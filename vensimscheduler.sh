#!/bin/bash

# Wait for teardown to complete before starting up
while [ ! -f /tmp/startup.done ]; do
    echo "Waiting for teardown to complete..."
    sleep 1
done


# Set variables
TARGET_DIR=~/manual-instruqt-startup
WORKLOAD_FILE=./vensim-templates/standard-demo/vens.csv
TRAFFIC_FILE=./vensim-templates/standard-demo/traffic.csv
PROCESS_FILE=./vensim-templates/standard-demo/processes.csv

# Function definitions for tasks
update_processes() {
  cd "$TARGET_DIR" && ./vensim update-processes -c "$WORKLOAD_FILE" -p "$PROCESS_FILE" >/dev/null 2>&1
}

post_traffic() {
  cd "$TARGET_DIR" && ./vensim post-traffic -c "$WORKLOAD_FILE" -t "$TRAFFIC_FILE" -d today >/dev/null 2>&1
}

heartbeat() {
  cd "$TARGET_DIR" && ./vensim heartbeat -c "$WORKLOAD_FILE" >/dev/null 2>&1
}

get_policy() {
  cd "$TARGET_DIR" && ./vensim get-policy -c "$WORKLOAD_FILE" >/dev/null 2>&1
}

cleanup_log() {
  cd "$TARGET_DIR" && rm -f vensim.log
}

# Scheduling using background loops
# Update processes at 6:00 AM daily
(
  while true; do
    now=$(date +%H:%M)
    if [ "$now" = "06:00" ]; then
      update_processes
      sleep 60  # Avoid running multiple times within the same minute
    fi
    sleep 30
  done
) &

# Post traffic every 10 minutes
(
  while true; do
    post_traffic
    sleep 600  # 10 minutes
  done
) &

# Heartbeat every 5 minutes
(
  while true; do
    heartbeat
    sleep 300  # 5 minutes
  done
) &

# Get policy every 15 seconds (4 times per minute)
(
  while true; do
    get_policy
    sleep 15
  done
) &

# Clean vensim log every hour at minute 0
(
  while true; do
    minute=$(date +%M)
    if [ "$minute" = "00" ]; then
      cleanup_log
      sleep 60
    fi
    sleep 30
  done
) &

# Keep the script running
wait
