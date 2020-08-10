#!/bin/sh

set -e

APP_NAME="dialer-api"
APP_USER=$(${APP_NAME} config:get APP_USER)
APP_RUN_DIR="/var/run/${APP_NAME}"

mkdir -p ${APP_RUN_DIR}
chown ${APP_USER}:nginx ${APP_RUN_DIR}
chmod g+w ${APP_RUN_DIR}

# Copy startup scripts to correct directory
/usr/bin/cp /opt/dialer-api/packaging/startup/dialer-api.service /lib/systemd/system/dialer-api.service

# Set dialer-api config variables
/usr/bin/dialer-api config:set DATABASE_URL=mysql2://root@localhost/tfdialer_db
