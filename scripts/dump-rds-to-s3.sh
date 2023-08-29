#!/usr/bin/env bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/questions/35800082/how-to-trap-err-when-using-set-e-in-bash/35800451#35800451
# https://www.shellcheck.net/ VERIFIED
set -e
set -E
set -o pipefail
set -u
set -x

IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

# https://stackoverflow.com/questions/64615854/bash-get-message-from-error-that-was-just-trapped/64616137#64616137
log="dump-rds-to-s3.log"
exec 2>"$log"

# https://stackoverflow.com/questions/64786/error-handling-in-bash/185900#185900
handle_error() {
    log_message="$(< "$log")"
    local from;
    local subject;
    local text;
    local to;
    from="cron@coinhexa.com"
    to="coinhexa@gmail.com"
    subject="RDS dump encountered an error at $(date)"
    text="RDS dump encountered an error at line:$(caller) while running:${BASH_COMMAND} due to the error:${log_message}"
    aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
    # echo "subject: ${subject}"
    # echo "text: ${text}"
    exit 1
}

handle_exit() {
    if [ $? -eq 0 ]; then
        log_message="$(< "$log")"
        local from;
        local subject;
        local text;
        local to;
        from="cron@coinhexa.com"
        to="coinhexa@gmail.com"
        subject="RDS dump completed successfully at $(date)"
        text="RDS dump completed successfully and files with size $(du -sh "${backup_dirname}.tar.gz" | sed 's/\t/ /g') were uploaded to S3 ${log_message}"
        aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
        # echo "subject: ${subject}"
        # echo "text: ${text}"
    fi

    # Delete the current backup folder with all files inside
    rm -rf "${backup_dirname}"

    # Delete the compressed backup folder
    rm "${backup_dirname}.tar.gz"

    # Delete the error log file
    rm "dump-rds-to-s3.log"
}

# https://stackoverflow.com/questions/76787024/why-is-the-exit-code-always-0-inside-handle-exit-and-how-to-distinguish-error-fr
trap 'handle_exit $?' EXIT
trap 'handle_error $?' ERR

# https://docs.aws.amazon.com/dms/latest/sbs/chap-manageddatabases.postgresql-rds-postgresql-full-load-pd_dump.html
# https://aws.amazon.com/blogs/database/best-practices-for-migrating-postgresql-databases-to-amazon-rds-and-amazon-aurora/
export PGPASSFILE="$HOME/.pgpass"
backup_dirname="$(date '+%Y_%m_%d_%HH_%MM_%SS')"
bucket_url="s3://test-ch-backups-rds"
dbname="coinhexa_api_db"
dump_filename="pg_${dbname}"
marker_filename="backup.done"
encoding="UTF8"
globals_filename="globals.dump"
host="test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com"
jobs="2"
port="26189"
username="postgres"

mkdir "${backup_dirname}"

cd "${backup_dirname}"

# https://stackoverflow.com/questions/64899405/how-can-i-run-pg-dumpall-with-heroku
# https://stackoverflow.com/questions/16786011/postgresql-pgpass-not-working
pg_dumpall \
    --globals-only \
    --no-password \
    --no-role-passwords \
    --encoding="${encoding}" \
    --file="${globals_filename}" \
    --host="${host}" \
    --port="${port}" \
    --username="${username}"

# https://dba.stackexchange.com/questions/48127/what-to-look-for-in-bad-pg-dump-log/48133#48133
pg_dump \
    --blobs \
    --create \
    --no-password \
    --dbname="${dbname}" \
    --encoding="${encoding}" \
    --file="${dump_filename}" \
    --format="directory" \
    --host="${host}" \
    --jobs="${jobs}" \
    --port="${port}" \
    --username="${username}"

# Add a marker so that we know backup was done
touch "${marker_filename}"

cd ..

# Compress the current backup directory
tar czvf "${backup_dirname}.tar.gz" "${backup_dirname}"

# Upload to S3
aws s3 cp "${backup_dirname}.tar.gz" "${bucket_url}"
