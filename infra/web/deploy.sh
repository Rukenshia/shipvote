#!/bin/bash

total_steps=10

getStatusStep() {
  case "$1" in
    "pending")              echo 1 ;;
    "plan_queued")          echo 2 ;;
    "planning")             echo 3 ;;
    "planned")              echo 4 ;;
    "cost_estimating")      echo 4 ;;
    "cost_estimated")       echo 4 ;;
    "policy_checking")      echo 5 ;;
    "apply_queued")         echo 6 ;;
    "applying")             echo 7 ;;
    "applied")              echo 8 ;;
    "planned_and_finished") echo 8 ;;
    "errored")              echo 8 ;;
    "canceled")             echo 8 ;;
    "discarded")            echo 8 ;;
  esac
}

# Trigger the run

response=$(curl -s \
  --header "Content-Type: application/vnd.api+json" \
  --header "Authorization: Bearer ${TFCLOUD_API_KEY}" \
  --request POST \
  --data "{\"data\": {\"attributes\": { \"message\": \"automated trigger after shipvote ami update\", \"is-destroy\": false, \"refresh\": true}, \"type\": \"runs\", \"relationships\": {\"workspace\": { \"data\": { \"type\": \"workspaces\", \"id\": \"${WORKSPACE_ID}\"}}}}}" \
  https://app.terraform.io/api/v2/runs)

# Extract run_id from response
run_id=$(echo ${response} | jq -r '.data.id')

prev_status=""
# Poll the status of the run every 5s
while true; do
  response=$(curl -s \
    --header "Authorization: Bearer ${TFCLOUD_API_KEY}" \
    https://app.terraform.io/api/v2/runs/${run_id})

  status=$(echo ${response} | jq -r '.data.attributes.status')

  # Only print when state changes
  if [ "$status" != "$prev_status" ]; then
    # Color output based on status
    case $status in
      "pending"|"plan_queued"|"planning"|"planned"|"cost_estimating"|"cost_estimated"|"policy_checking"|"apply_queued"|"applying")
        printf "\e[34m%s\e[0m (%s/%s)\n" "${status}" "$(getStatusStep $status)" "$total_steps" # Blue for these statuses
        ;;
      "applied"|"planned_and_finished")
        printf "\e[32m%s\e[0m (%s/%s)\n" "${status}" "$(getStatusStep $status)" "$total_steps" # Green for applied and planned_and_finished
        ;;
      "errored")
        printf "\e[31m%s\e[0m (%s/%s)\n" "${status}" "$(getStatusStep $status)" "$total_steps" # Red for errored
        ;;
      "canceled")
        printf "\e[33m%s\e[0m (%s/%s)\n" "${status}" "$(getStatusStep $status)" "$total_steps" # Yellow for canceled
        ;;
      *)
        printf "%s (%s/%s)\n" "${status}" "$(getStatusStep $status)" "$total_steps" # Normal color for other statuses
        ;;
    esac
    prev_status="$status"
  fi

  # Check final statuses to exit the loop
  if [[ "${status}" == "applied" || "${status}" == "planned_and_finished" || "${status}" == "errored" || "${status}" == "canceled" || "${status}" == "discarded" ]]; then
    break
  fi

  sleep 5
done
