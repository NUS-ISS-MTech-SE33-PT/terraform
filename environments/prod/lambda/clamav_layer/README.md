Build the ClamAV Lambda layer before running Terraform from this repo:

```bash
./scripts/build-clamav-layer.sh
```

The script writes `clamav-layer.zip` into this directory. The archive is ignored by git and consumed by `environments/prod/lambda_spot_submission_scan.tf`.
