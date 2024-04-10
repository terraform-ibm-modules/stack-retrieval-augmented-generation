#!/bin/bash

set -x

PROJECT_ID="bdad81fb-e28b-4ce7-aea4-72ab81c8718d"
CONFIG_IDS=("64271bc0-c3b6-4828-b7b5-b6024d9e3598")

function validate_config() {
  ibmcloud project config-validate --project-id $PROJECT_ID --id $CONFIG_ID --output json > /tmp/validation.json
}

function wait_for_validation() {
  # Loop until the state is set to validated
  while true; do

    # Get the current state of the configuration
    STATE=$(ibmcloud project config --project-id $PROJECT_ID --id $CONFIG_ID --output json | jq -r '.state')

    if [[ "$STATE" == "validated" ]]; then
      break
    fi

    if [[ "$STATE" != "validating" ]]; then
      echo "Error: Unexpected state $STATE"
      exit 1
    fi

    sleep 10 
  done
}

function approve_config() {
  ibmcloud project config-approve --project-id $PROJECT_ID --id $CONFIG_ID --comment "I approve through CLI"
}

function deploy_config() {
  ibmcloud project config-deploy --project-id $PROJECT_ID --id $CONFIG_ID
}

function wait_for_deployment() {
  while true; do
    # Retrieve the configuration
    RESPONSE=$(ibmcloud project config --project-id $PROJECT_ID --id $CONFIG_ID --output json)

    # Check the state of the configuration under approved_version
    STATE=$(echo "$RESPONSE" | jq -r ".approved_version.state")

    # If the state is "deployed" or "deploying_failed", exit the loop
    if [[ "$STATE" == "deployed" || "$STATE" == "deploying_failed" ]]; then
      break
    fi

    # If the state is not "deploying", print an error message and exit
    if [[ "$STATE" != "deploying" ]]; then
      echo "Error: Unexpected state $STATE"
      exit 1
    fi

    # Sleep for a few seconds before checking the state again
    sleep 10
  done
}

# 6. Loop through the configuration IDs and execute the functions
for CONFIG_ID in "${CONFIG_IDS[@]}"
do
  validate_config
  wait_for_validation
  approve_config
  deploy_config
  wait_for_deployment
done
