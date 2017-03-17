#! /bin/sh

set -e

if [ "${S3_ACCESS_KEY_ID}" == "**None**" ]; then
  echo "Warning: You did not set the S3_ACCESS_KEY_ID environment variable."
fi

if [ "${S3_SECRET_ACCESS_KEY}" == "**None**" ]; then
  echo "Warning: You did not set the S3_SECRET_ACCESS_KEY environment variable."
fi

if [ "${S3_BUCKET}" == "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" == "**None**" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" == "**None**" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" == "**None**" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ "${RESTORE_DB_NAME}" == "**None**" ]; then
  echo "You need to set the RESTORE_DB_NAME environment variable."
  exit 1
fi

if [ "${RESTORE_FILENAME}" == "**None**" ]; then
  echo "You need to set the RESTORE_FILENAME environment variable. (e.g., 2017-03-17T021827Z.dump.sql.gz)"
  exit 1
fi

if [ "${S3_IAMROLE}" != "true" ]; then
  # env vars needed for aws tools - only if an IAM role is not used
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION
fi

MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

if [ "$1" == "" ]; then
    echo "You did not choose any file to download;"
    echo "e.g., 2017-03-17T021827Z.dump.sql.gz"
fi

if [ "${S3_ENDPOINT}" == "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# Create database and grant permissions
echo "DROP DATABASE IF EXISTS ${RESTORE_DB_NAME}; CREATE DATABASE ${RESTORE_DB_NAME}; GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;" | mysql $MYSQL_HOST_OPTS

aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$1 - | gzip -dc | mysql $MYSQL_HOST_OPTS $RESTORE_DB_NAME

if [ "$?" == "0" ]; then
  echo ">>> Restoring process success!"
else
  echo ">>> Restoring process fail"
fi
