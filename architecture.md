# Makan-Go Architecture Diagrams

> Rendered natively on GitHub. To use in Word/PowerPoint, paste the diagram source into [mermaid.live](https://mermaid.live), then export as PNG.

---

## 1. Cloud Architecture

```mermaid
flowchart TD
    subgraph Clients["Clients"]
        MOB["📱 Mobile App\n(Android)"]
        WEB["🌐 Web Browser\n(User)"]
        ADM["🖥️ Web Browser\n(Admin)"]
    end

    subgraph AuthLayer["Authentication"]
        COG["Amazon Cognito\nUser Pool · JWT Issuer"]
    end

    subgraph CDN["CDN & Security  ·  us-east-1"]
        WAF["AWS WAF\nIP Reputation · Common Rules · Rate Limit"]
        CF_WEB["CloudFront\nWeb Static"]
        CF_ADM["CloudFront\nAdmin Web"]
        CF_SUB["CloudFront\nSpot Submissions"]
        WAF --> CF_WEB & CF_ADM
    end

    subgraph S3Layer["Static Assets  ·  S3"]
        S3_WEB["makan-go-web-static"]
        S3_ADM["makan-go-admin-web"]
        S3_SUB["makan-go-spot-submissions\n(presigned upload + 365d lifecycle)"]
    end

    APIG["API Gateway HTTP API\n(JWT Authorizer via Cognito)"]

    subgraph VPC["VPC 10.0.0.0/16  ·  ap-southeast-1"]
        VPCL["VPC Link"]
        subgraph ECS["ECS Fargate  ·  prod-cluster"]
            direction TB
            NLB1["NLB (internal)"] --> SVC1["Review Service\n256 CPU · 512 MB"]
            NLB2["NLB (internal)"] --> SVC2["Spot Service\n256 CPU · 512 MB"]
            NLB3["NLB (internal)"] --> SVC3["Spot Submission Service\n256 CPU · 512 MB"]
        end
    end

    subgraph DataLayer["Data Layer"]
        DDB1[("reviews-prod")]
        DDB2[("favorites-prod")]
        DDB3[("spots-prod")]
        DDB4[("spot-submissions-prod")]
    end

    CW["☁️ CloudWatch Logs\n(7-day retention)"]

    %% Auth flow
    MOB & WEB & ADM -->|"login / token"| COG

    %% Static web
    WEB --> CF_WEB --> S3_WEB
    ADM --> CF_ADM --> S3_ADM
    CF_SUB --> S3_SUB

    %% API calls
    MOB & WEB & ADM -->|"HTTPS + JWT"| APIG
    COG -.->|"validates JWT"| APIG

    %% API to services via VPC
    APIG --> VPCL
    VPCL --> NLB1 & NLB2 & NLB3

    %% Service to data
    SVC1 --> DDB1 & DDB2
    SVC2 --> DDB3
    SVC3 --> DDB4 & DDB3
    SVC3 -->|"presigned URL"| S3_SUB

    %% Logging
    SVC1 & SVC2 & SVC3 & APIG --> CW
```

---

## 2. Request Flow (Microservice Interaction)

Two representative flows are shown: a public read and an authenticated write.

```mermaid
sequenceDiagram
    actor User as User (Mobile / Web)
    participant COG as Cognito
    participant APIG as API Gateway
    participant SVC_SPOT as Spot Service
    participant SVC_REV as Review Service
    participant SVC_SUB as Spot Submission Service
    participant DDB as DynamoDB
    participant S3 as S3

    Note over User,S3: Flow A — Browse spots (no auth required)

    User->>APIG: GET /spots
    APIG->>SVC_SPOT: forward request (no JWT check)
    SVC_SPOT->>DDB: query spots-prod
    DDB-->>SVC_SPOT: spot records
    SVC_SPOT-->>APIG: 200 OK + spot list
    APIG-->>User: spot list

    Note over User,S3: Flow B — Post a review (auth required)

    User->>COG: login (email + password)
    COG-->>User: JWT access token

    User->>APIG: POST /spots/{id}/reviews\n+ Authorization: Bearer <JWT>
    APIG->>COG: validate JWT
    COG-->>APIG: valid · claims (sub, email)
    APIG->>SVC_REV: forward request + x-user-sub header
    SVC_REV->>DDB: put item → reviews-prod
    DDB-->>SVC_REV: OK
    SVC_REV-->>APIG: 201 Created
    APIG-->>User: 201 Created

    Note over User,S3: Flow C — Submit a spot with photo (auth required)

    User->>APIG: POST /spots/submissions/photos/presign\n+ Authorization: Bearer <JWT>
    APIG->>SVC_SUB: forward (JWT validated)
    SVC_SUB->>S3: generate presigned PUT URL\n(15 min expiry)
    S3-->>SVC_SUB: presigned URL
    SVC_SUB-->>User: presigned URL

    User->>S3: PUT photo (direct upload via presigned URL)
    S3-->>User: 200 OK

    User->>APIG: POST /spots/submissions\n+ photo reference + JWT
    APIG->>SVC_SUB: forward
    SVC_SUB->>DDB: put item → spot-submissions-prod
    DDB-->>SVC_SUB: OK
    SVC_SUB-->>User: 201 Created
```

---

## 3. CI/CD Pipeline

Based on the agreed tag-based promotion strategy (not yet fully implemented — see CLAUDE.md).

```mermaid
flowchart TD
    A(["Developer\npushes to feature branch"]) --> B

    subgraph PR["Pull Request"]
        B["Open PR to main\n(direct push to main is blocked)"]
        C{"Peer review\napproved?"}
        B --> C
    end

    C -->|No| B
    C -->|Yes| D["Merge to main\n(merge commit created)"]

    subgraph CI["CI Pipeline  ·  runs on merge commit"]
        D --> E["Run unit tests"]
        D --> F["Run API tests"]
        E & F --> G{"All checks\npassed?"}
    end

    G -->|No| FAIL1(["❌ Pipeline fails\nno tag created"])
    G -->|Yes| H["Auto-create tag\nci-passed/vX.Y.Z"]

    H --> I(["Developer decides\nmajor / minor / patch"])
    I --> J["Manually push tag\nrc/vX.Y.Z"]

    subgraph GATE["Deployment Gate"]
        J --> K{"ci-passed/vX.Y.Z\nexists on this commit?"}
        K -->|No| FAIL2(["❌ Deploy blocked"])
        K -->|Yes| L["GitHub Environment: prod\nAuto gate ✅"]
        L --> M{"Manual approval\nby reviewer"}
        M -->|Rejected| FAIL3(["❌ Deploy cancelled"])
    end

    M -->|Approved| N["deploy-prod.yml\nterraform apply"]

    subgraph DEPLOY["Deployment  ·  ap-southeast-1"]
        N --> O{"Terraform\napply succeeded?"}
        O -->|No| FAIL4(["❌ Deploy failed\nlive tag unchanged"])
        O -->|Yes| P["Force-update tag: live\n(always = current prod commit)"]
    end

    P --> Q(["✅ Live\nECS services running"])
```

---

## Data Model (DynamoDB Tables)

```mermaid
erDiagram
    SPOTS {
        string id PK
    }

    REVIEWS {
        string id PK
        string userId
        string spotId
        string createdAt
    }

    FAVORITES {
        string userId PK
        string spotId SK
    }

    SPOT_SUBMISSIONS {
        string id PK
    }

    SPOTS ||--o{ REVIEWS : "reviewed via"
    SPOTS ||--o{ FAVORITES : "favourited via"
    SPOTS ||--o{ SPOT_SUBMISSIONS : "submitted as"
```
