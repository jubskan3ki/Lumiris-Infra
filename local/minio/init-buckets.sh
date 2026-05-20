#!/usr/bin/env sh
set -e

until mc alias set local "http://minio:9000" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" 2>/dev/null; do
  echo "[minio-init] waiting for minio..."
  sleep 2
done

echo "[minio-init] minio alias set"

for bucket in "${MINIO_BUCKET_UPLOADS}" "${MINIO_BUCKET_CDN}" "${MINIO_BUCKET_BACKUPS}"; do
  if mc ls "local/${bucket}" >/dev/null 2>&1; then
    echo "[minio-init] bucket ${bucket} already exists"
  else
    mc mb "local/${bucket}"
    echo "[minio-init] bucket ${bucket} created"
  fi
done

mc anonymous set download "local/${MINIO_BUCKET_CDN}" || true
echo "[minio-init] cdn bucket anonymous download set"

if mc admin user info local "${MINIO_APP_USER}" >/dev/null 2>&1; then
  echo "[minio-init] app user already exists"
else
  mc admin user add local "${MINIO_APP_USER}" "${MINIO_APP_PASSWORD}"
  echo "[minio-init] app user created"
fi

mc admin policy attach local readwrite --user "${MINIO_APP_USER}" || true
echo "[minio-init] readwrite policy attached"

echo "[minio-init] done"
