import json
import logging
import os
import posixpath
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote_plus

import boto3
from botocore.exceptions import ClientError


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

S3 = boto3.client("s3")

BUCKET_NAME = os.environ.get("BUCKET_NAME", "")
KEY_PREFIX = os.environ.get("KEY_PREFIX", "submissions/").strip("/")
SCAN_STATUS_TAG_KEY = os.environ.get("SCAN_STATUS_TAG_KEY", "scan-status")
CLEAN_SCAN_STATUS = os.environ.get("CLEAN_SCAN_STATUS", "clean")
INFECTED_SCAN_STATUS = os.environ.get("INFECTED_SCAN_STATUS", "infected")
ERROR_SCAN_STATUS = os.environ.get("ERROR_SCAN_STATUS", "error")
CLAMSCAN_PATH = os.environ.get("CLAMSCAN_PATH", "/opt/bin/clamscan")
FRESHCLAM_PATH = os.environ.get("FRESHCLAM_PATH", "/opt/bin/freshclam")
CLAMAV_DATABASE_DIR = os.environ.get("CLAMAV_DATABASE_DIR", "/tmp/clamav-db")
CLAMSCAN_TIMEOUT_SECONDS = int(os.environ.get("CLAMSCAN_TIMEOUT_SECONDS", "120"))
FRESHCLAM_TIMEOUT_SECONDS = int(os.environ.get("FRESHCLAM_TIMEOUT_SECONDS", "240"))
FRESHCLAM_COOLDOWN_MINUTES = int(os.environ.get("FRESHCLAM_COOLDOWN_MINUTES", "360"))
SCAN_ENGINE_TAG_KEY = "scan-engine"
SCAN_DETAIL_TAG_KEY = "scan-detail"
SCAN_AT_TAG_KEY = "scan-at"
MANAGED_TAG_KEYS = {
    SCAN_STATUS_TAG_KEY,
    SCAN_ENGINE_TAG_KEY,
    SCAN_DETAIL_TAG_KEY,
    SCAN_AT_TAG_KEY,
}
JPEG_SIGNATURE = bytes([0xFF, 0xD8, 0xFF])
PNG_SIGNATURE = bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
WEBP_SIGNATURE = bytes([0x52, 0x49, 0x46, 0x46])
WEBP_SUFFIX = bytes([0x57, 0x45, 0x42, 0x50])
EXTENSION_TO_MIME = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
}


def handler(event, _context):
    LOGGER.info("Received event: %s", json.dumps(event))

    for record in event.get("Records", []):
        if record.get("eventSource") != "aws:s3":
            continue

        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        try:
            scan_object(bucket, key)
        except Exception as exc:  # pragma: no cover - defensive logging path
            LOGGER.exception("Unexpected scan failure for s3://%s/%s", bucket, key)
            safe_tag_object(
                bucket,
                key,
                ERROR_SCAN_STATUS,
                engine="clamav",
                detail=f"exception:{type(exc).__name__}",
            )


def scan_object(bucket, key):
    if bucket != BUCKET_NAME or not key.startswith(f"{KEY_PREFIX}/"):
        LOGGER.info("Skipping unrelated object s3://%s/%s", bucket, key)
        return

    try:
        metadata = S3.head_object(Bucket=bucket, Key=key)
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") == "404":
            LOGGER.warning("Object missing before scan: s3://%s/%s", bucket, key)
            return
        raise

    content_type = normalize_content_type(metadata.get("ContentType", ""))
    extension = posixpath.splitext(key)[1].lower()

    with tempfile.NamedTemporaryFile(dir="/tmp", delete=False) as temp_file:
        download_path = temp_file.name

    try:
        S3.download_file(bucket, key, download_path)
        mismatch_reason = validate_image_structure(download_path, content_type, extension)
        if mismatch_reason is not None:
            safe_tag_object(bucket, key, INFECTED_SCAN_STATUS, engine="header-check", detail=mismatch_reason)
            return

        clamscan_path = resolve_executable(CLAMSCAN_PATH)
        freshclam_path = resolve_executable(FRESHCLAM_PATH)
        if not clamscan_path or not freshclam_path:
            safe_tag_object(bucket, key, ERROR_SCAN_STATUS, engine="clamav", detail="clamav-binaries-missing")
            return

        ensure_virus_definitions(freshclam_path)

        result = subprocess.run(
            [
                clamscan_path,
                f"--database={CLAMAV_DATABASE_DIR}",
                "--no-summary",
                download_path,
            ],
            capture_output=True,
            text=True,
            timeout=CLAMSCAN_TIMEOUT_SECONDS,
            check=False,
        )

        if result.returncode == 0:
            safe_tag_object(bucket, key, CLEAN_SCAN_STATUS, engine="clamav")
            return

        if result.returncode == 1:
            safe_tag_object(bucket, key, INFECTED_SCAN_STATUS, engine="clamav", detail=extract_scan_detail(result))
            return

        safe_tag_object(
            bucket,
            key,
            ERROR_SCAN_STATUS,
            engine="clamav",
            detail=f"clamav-exit-{result.returncode}",
        )
    finally:
        try:
            os.remove(download_path)
        except FileNotFoundError:
            pass


def validate_image_structure(file_path, content_type, extension):
    expected_content_type = EXTENSION_TO_MIME.get(extension)
    if expected_content_type is None:
        return "unsupported-extension"

    if content_type != expected_content_type:
        return "content-type-mismatch"

    with open(file_path, "rb") as uploaded_file:
        header = uploaded_file.read(16)

    detected_content_type = detect_content_type(header)
    if detected_content_type == "":
        return "unsupported-header"

    if detected_content_type != content_type:
        return "header-content-type-mismatch"

    return None


def detect_content_type(header):
    if len(header) >= 3 and header[:3] == JPEG_SIGNATURE:
        return "image/jpeg"

    if len(header) >= 8 and header[:8] == PNG_SIGNATURE:
        return "image/png"

    if len(header) >= 12 and header[:4] == WEBP_SIGNATURE and header[8:12] == WEBP_SUFFIX:
        return "image/webp"

    return ""


def normalize_content_type(content_type):
    return content_type.split(";", 1)[0].strip().lower()


def resolve_executable(candidate_path):
    if os.path.basename(candidate_path) == candidate_path:
        return shutil.which(candidate_path)

    return candidate_path if os.path.exists(candidate_path) else None


def ensure_virus_definitions(freshclam_path):
    database_directory = Path(CLAMAV_DATABASE_DIR)
    database_directory.mkdir(parents=True, exist_ok=True)

    if not should_refresh_database(database_directory):
        return

    config_path = database_directory / "freshclam.conf"
    log_path = database_directory / "freshclam.log"
    config_path.write_text(
        "\n".join(
            [
                f"DatabaseDirectory {database_directory}",
                "DatabaseMirror database.clamav.net",
                "DNSDatabaseInfo current.cvd.clamav.net",
                "Foreground true",
                f"UpdateLogFile {log_path}",
                "LogVerbose false",
                "LogTime true",
                "Checks 1",
                "",
            ]
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            freshclam_path,
            f"--config-file={config_path}",
            f"--datadir={database_directory}",
            "--stdout",
        ],
        capture_output=True,
        text=True,
        timeout=FRESHCLAM_TIMEOUT_SECONDS,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"freshclam failed with exit code {result.returncode}: {extract_scan_detail(result)}")

    (database_directory / ".last_refresh").write_text(
        datetime.now(timezone.utc).isoformat(timespec="seconds"),
        encoding="utf-8",
    )


def should_refresh_database(database_directory):
    last_refresh_file = database_directory / ".last_refresh"
    if not last_refresh_file.exists():
        return True

    try:
        last_refresh = datetime.fromisoformat(last_refresh_file.read_text(encoding="utf-8").strip())
    except ValueError:
        return True

    age = datetime.now(timezone.utc) - last_refresh
    return age.total_seconds() >= FRESHCLAM_COOLDOWN_MINUTES * 60


def extract_scan_detail(result):
    combined_output = "\n".join(part for part in [result.stdout, result.stderr] if part)
    first_line = combined_output.strip().splitlines()[0] if combined_output.strip() else "infected"
    return sanitize_tag_value(first_line)


def safe_tag_object(bucket, key, status, engine, detail=None):
    try:
        existing_tags = S3.get_object_tagging(Bucket=bucket, Key=key).get("TagSet", [])
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") == "NoSuchKey":
            LOGGER.warning("Unable to tag deleted object s3://%s/%s", bucket, key)
            return
        raise

    merged_tags = {}
    for tag in existing_tags:
        tag_key = tag["Key"]
        if tag_key in MANAGED_TAG_KEYS:
            continue
        if len(merged_tags) >= 6:
            break
        merged_tags[tag_key] = tag["Value"]

    merged_tags[SCAN_STATUS_TAG_KEY] = status
    merged_tags[SCAN_ENGINE_TAG_KEY] = sanitize_tag_value(engine)
    merged_tags[SCAN_AT_TAG_KEY] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    if detail:
        merged_tags[SCAN_DETAIL_TAG_KEY] = sanitize_tag_value(detail)

    tag_set = [{"Key": tag_key, "Value": tag_value} for tag_key, tag_value in merged_tags.items()]
    S3.put_object_tagging(Bucket=bucket, Key=key, Tagging={"TagSet": tag_set})
    LOGGER.info("Tagged s3://%s/%s with %s", bucket, key, merged_tags)


def sanitize_tag_value(value):
    normalized = value.strip().replace("\n", " ").replace("\r", " ")
    return normalized[:256]
