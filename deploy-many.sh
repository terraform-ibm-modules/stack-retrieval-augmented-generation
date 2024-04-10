#!/bin/bash

set -x



PROJECT_ID="440acf2a-896f-4426-968b-581fb0eb83f4"
CONFIG_IDS=("9618c574-4e0d-4e89-ac55-440717c8b378" "545c1a92-fa21-447f-96ed-fbefb7c50b35" "9aca1cae-36e3-4d1a-96fe-a4ddec057c01" "3eab3b42-f8d4-4532-b0d2-05ef2cc9c250" "b3dbe0de-1512-4351-b0f5-bb8ae8be4d4b")
STACK_CONFIG_ID="abb2b55e-aa3f-42a9-9897-167cca2e5229"

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
