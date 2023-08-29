#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
# https://stackoverflow.com/a/71738522/5371505
# https://www.shellcheck.net/ VERIFIED
set -e
set -E
set -o pipefail
set -u
set -x

IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

# https://stackoverflow.com/a/64616137/5371505
log="restore-rds-to-docker.log"
exec 2>"$log"

# https://stackoverflow.com/questions/64786/error-handling-in-bash/185900#185900
handle_error() {    
    log_message="$(< "$log")"
    local from;
    local to;
    local subject;
    local text;
    from="cron@coinhexa.com"
    to="coinhexa@gmail.com"
    subject="RDS restore encountered an error at $(date)"
    text="RDS restore encountered an error at line:$(caller) while running:${BASH_COMMAND} due to the error:${log_message}"
    aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
    # echo "subject: ${subject}"
    # echo "text: ${text}"
    exit 1
}

handle_exit() {
    if [ $? -eq 0 ]; then
        log_message="$(< "$log")"
        local from;
        local to;
        local subject;
        local text;
        from="cron@coinhexa.com"
        to="coinhexa@gmail.com"
        subject="RDS restore completed successfully at $(date)"
        text="RDS restore completed successfully ${log_message} ${result}"
        aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
        # echo "subject: ${subject}"
        # echo "text: ${text}"
    fi

    docker stop "${container_name}" && docker rm "${container_name}"

    # Delete the tar.gz file
    rm "${archive_name}"

    # Delete the extracted directory
    rm -rf "${backup_dirname}"

    # Delete the error log file
    rm "restore-rds-to-docker.log"
}

# https://stackoverflow.com/questions/76787024/why-is-the-exit-code-always-0-inside-handle-exit-and-how-to-distinguish-error-fr
trap 'handle_exit $?' EXIT
trap 'handle_error $?' ERR


# remove any downloaded directories

# trap error
# trap exit

bucket='test-ch-backups-rds'
container_name="my_postgres_container"
globals_filename="globals.dump"
host="localhost"
jobs="2"
nonroot_dbname="coinhexa_api_db"
dump_filename="pg_${nonroot_dbname}"
nonroot_username="coinhexa_api_user"
port="5432"
postgres_version="14.8"
result=""
root_username="postgres"

# https://stackoverflow.com/a/31064378/5371505
archive_name=$(aws s3 ls $bucket --recursive | sort | tail -n 1 | awk '{print $4}')

# https://linuxhint.com/read_filename_without_extension_bash/
backup_dirname=$(basename "${archive_name}" .tar.gz)

aws s3 cp "s3://${bucket}/${archive_name}" "${archive_name}"

tar xvzf "${archive_name}" "${backup_dirname}"

cd "${backup_dirname}"

if [ ! -f  "backup.done" ]; then
    # Trigger the err trap with a bad command
    backup_dot_done_file_was_not_found_inside_the_dump
fi

# https://stackoverflow.com/a/44364288/5371505
docker ps -aq --filter "name=${container_name}" | grep -q . && docker stop "${container_name}" && docker rm -fv "${container_name}"

# Run the Docker container
docker run --detach --name "${container_name}" --publish "${port}:${port}" -e POSTGRES_PASSWORD=mypassword "postgres:${postgres_version}"

# Wait for the Docker container to be ready
until docker exec -it "${container_name}" psql --username="${root_username}" --command="SELECT 1 AS working"; do
    echo "Waiting for postgres container to be up $(date)"
    sleep 10
done

docker cp "globals.dump" "${container_name}:/home/globals.dump"
docker cp "pg_coinhexa_api_db" "${container_name}:/home/pg_coinhexa_api_db"
docker exec -it "${container_name}" sh -c "psql --no-password --quiet --host=${host} --port=${port} --username=${root_username} --file=/home/${globals_filename}"
docker exec -it "${container_name}" sh -c "createdb --no-password --encoding=UTF8 --owner=${nonroot_username} --host=${host} --port=${port} --username=${nonroot_username} ${nonroot_dbname}"
docker exec -it "${container_name}" sh -c "pg_restore --disable-triggers --exit-on-error --format=directory --dbname=${nonroot_dbname} --host=${host} --jobs=${jobs} --port=${port} --username=${nonroot_username} /home/${dump_filename}"
result=$(docker exec "${container_name}" sh -c "psql --no-password --dbname=${nonroot_dbname} --host=${host} --port=${port} --username=${nonroot_username} -c '\\dt+'")
cd ..
