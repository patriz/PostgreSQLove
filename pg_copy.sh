#!/usr/bin/env bash

DUMP_DB_HOST="prod.xxxxx.ap-northeast-2.rds.amazonaws.com"
DUMP_DB_NAME="db"
DUMP_DB_USER="user"
DUMP_DB_PORT=5432
DUMP_DB_PASS="password"
DUMP_DB_OPTS="--cluster 9.6/main"

RESTORE_DB_HOST="stage.xxxxx.ap-northeast-2.rds.amazonaws.com"
RESTORE_DB_NAME="db"
RESTORE_DB_USER="user"
RESTORE_DB_PORT=5432
RESTORE_DB_PASS="password"

bash -c "PGPASSWORD=$DUMP_DB_PASS pg_dump --format=c \
            -h $DUMP_DB_HOST \
            -U $DUMP_DB_USER \
            -d $DUMP_DB_NAME \
            -p $DUMP_DB_PORT \
            $DUMP_DB_OPTS | \
        PGPASSWORD=$RESTORE_DB_PASS pg_restore -c \
            -h $RESTORE_DB_HOST \
            -U $RESTORE_DB_USER \
            -d $RESTORE_DB_NAME \
            -p $RESTORE_DB_PORT"
