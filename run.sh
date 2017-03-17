#! /bin/sh

set -e

if [ "${S3_S3V4}" = "yes" ]; then
  aws configure set default.s3.signature_version s3v4
fi

if [ "${RESTORE_DB_NAME}" != "**None**" ] && [ "${RESTORE_FILENAME}" != "**None**" ]; then
  sh restore.sh $RESTORE_FILENAME
  exit
fi

if [ "${SCHEDULE}" = "**None**" ]; then
  sh backup.sh
  exit
else
  exec go-cron "$SCHEDULE" /bin/sh backup.sh
fi
