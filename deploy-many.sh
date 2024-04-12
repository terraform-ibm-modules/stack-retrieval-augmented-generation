#!/bin/bash

set -x



PROJECT_ID="546993cb-c1ba-49cd-a975-187a2b924c21"
CONFIG_IDS=("70667b97-6bb5-425b-8e6a-47c931740604")
STACK_CONFIG_ID="53ef9a25-3aad-4167-b548-41b19c57cad4"

function set_stack_inputs() {
  ibmcloud project config-update --project-id $PROJECT_ID --id $STACK_CONFIG_ID --definition @.def.json
}

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
  set_stack_inputs
  validate_config
  wait_for_validation
  approve_config
  deploy_config
  wait_for_deployment
done
