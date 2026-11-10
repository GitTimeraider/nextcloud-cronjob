#!/usr/bin/env bash
set -e
[[ ! -z "$DEBUG" ]] && set -x

source /nextcloud-exec.sh

if [[ -z "$NEXTCLOUD_CONTAINER_NAME" ]]; then
    echo "NEXTCLOUD_CONTAINER_NAME is a required variable"
    exit 1
fi

# Print info about how we will look for Nextcloud
if [[ -n "$NEXTCLOUD_PROJECT_NAME" ]]; then
    echo "Will search for Nexcloud container as a Docker Compose service"
    echo "Project: $NEXTCLOUD_PROJECT_NAME, Service: $NEXTCLOUD_CONTAINER_NAME"
else
    echo "Container Name: $NEXTCLOUD_CONTAINER_NAME"
fi

# Wait for the Nextcloud container to become available. Instead of exiting when it can't be found
# (e.g. Nextcloud is still starting, being updated, or temporarily down), keep retrying.
retryInterval="${NEXTCLOUD_RETRY_INTERVAL:-60}"
if ! [[ "$retryInterval" =~ ^[0-9]+$ ]] || (( retryInterval < 1 )); then
    echo "WARNING: Invalid NEXTCLOUD_RETRY_INTERVAL \"$retryInterval\", falling back to 60 seconds"
    retryInterval=60
fi

while true; do
    containerId="$(/find-container.sh || true)"
    if [[ -n "$containerId" ]]; then
        echo "Found Nextcloud container with ID $containerId"
        break
    fi
    echo "WARNING: Unable to find the Nextcloud container, retrying in ${retryInterval}s ($(date))"
    sleep "$retryInterval"
done

# Verify the chosen shell exists in the Nextcloud container
if ! nextcloud_exec_no_shell "$containerId" sh -c "command -v \"$NEXTCLOUD_EXEC_SHELL\"" >/dev/null 2>&1
then
    echo "ERROR: Shell \"$NEXTCLOUD_EXEC_SHELL\" does not exist in the Nextcloud container"
    exit 1
else
    echo "Chosen shell \"$NEXTCLOUD_EXEC_SHELL\" was found in the Nextcloud container"
fi

echo "*/$NEXTCLOUD_CRON_MINUTE_INTERVAL * * * * /cron-tasks.sh" \
    > /var/spool/cron/crontabs/root

echo "Starting crond"
exec crond -f -l 0
