#!/bin/bash

set -x

function parse_params() {
  PROJECT_NAME=$1
  STACK_NAME=$2
  CONFIG_PATTERN=$3
  [[ -z "$PROJECT_NAME" && -z "$PROJECT_ID" || -z "$STACK_NAME" && -z "$STACK_CONFIG_ID"  ]] && \
    die "Usage: $(basename "${BASH_SOURCE[0]}") project_name stack_name [config_name_pattern]"

  if [[ -z $DRY_RUN ]]; then
    CLI_CMD=ibmcloud
  else
    # shellcheck disable=SC2209
    CLI_CMD=echo
  fi
}

function get_config_ids() {

  if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID=$( ibmcloud project list --all-pages --output json | jq -r --arg project_name "$PROJECT_NAME" '.projects[]? | select(.definition.name == $project_name) | .id' )
  fi
  [[ -z "$PROJECT_ID" ]] && die "ERROR!!! Project $PROJECT_NAME is not found"

  if [[ -z "$STACK_CONFIG_ID" ]]; then
    STACK_CONFIG_ID=$(ibmcloud project configs --project-id "$PROJECT_ID" --output json | jq -r --arg conf "$STACK_NAME" '.configs[]? | select(.definition.name==$conf) | .id ')
  fi
  [[ -z "$STACK_CONFIG_ID" ]] && die "ERROR!!! Stack Configuration $STACK_NAME is not found in project $PROJECT_NAME"


  if [[ -z "$CONFIG_IDS" ]]; then
    # shellcheck disable=SC2207
    CONFIG_IDS=($(ibmcloud project configs --project-id "$PROJECT_ID" --output json | jq -r --arg pattern "$CONFIG_PATTERN" '[.configs[]? | select((.definition.name | test($pattern)) and (.deployment_model != "stack"))] | sort_by(.definition.name)[] | .id'))
  fi
  # shellcheck disable=SC2128
  [[ -z "$CONFIG_IDS" ]] && die "ERROR!!! No configurations found matching '$CONFIG_PATTERN' in project $PROJECT_NAME"
}

function set_stack_inputs() {
  $CLI_CMD project config-update --project-id "$PROJECT_ID" --id "$STACK_CONFIG_ID" --definition @.def.json
}

function get_validation_state() {
  if [[ -n $DRY_RUN ]]; then
    echo "validated"
  else
    $CLI_CMD project config --project-id "$PROJECT_ID" --id "$CONFIG_ID" --output json | jq -r '.state'
  fi
}

function get_deployment_state() {
  if [[ -n $DRY_RUN ]]; then
    echo "deployed"
  else
    $CLI_CMD project config --project-id "$PROJECT_ID" --id "$CONFIG_ID" --output json | jq -r ".approved_version.state"
  fi
}

function validate_config() {
  echo "=========> Starting validation for $(ibmcloud project config --project-id "$PROJECT_ID" --id "$CONFIG_ID" --output json| jq -r '.definition.name')"

  STATE=$(get_validation_state)

  if [[ "$STATE" != "validated" && "$STATE" != "deployed" && "$STATE" != "deploying_failed" && "$STATE" != "approved" && "$STATE" != "deleting" && "$STATE" != "deleting_failed" ]]; then
    $CLI_CMD project config-validate --project-id "$PROJECT_ID" --id "$CONFIG_ID" --output json > /tmp/validation.json
  fi
}

function wait_for_validation() {
  # Loop until the state is set to validated
  while true; do

    STATE=$(get_validation_state)

    if [[ "$STATE" == "validated" || "$STATE" == "deployed" || "$STATE" == "deploying_failed" || "$STATE" == "approved" || "$STATE" == "deploying" || "$STATE" == "deleting" || "$STATE" == "deleting_failed" ]]; then
      break
    fi

    if [[ "$STATE" != "validating" ]]; then
      echo "Error: Unexpected state $STATE"
      exit 1
    fi

    sleep 10
    keep_iam_session_active
  done
}

function approve_config() {
  if [[ "$STATE" == "validated" ]]; then
    $CLI_CMD project config-approve --project-id "$PROJECT_ID" --id "$CONFIG_ID" --comment "I approve through CLI"
  fi
}

function deploy_config() {

  STATE=$(get_deployment_state)

  if [[ "$STATE" != "deployed" && "$STATE" != "deleting" && "$STATE" != "deleting_failed" ]]; then
    $CLI_CMD project config-deploy --project-id "$PROJECT_ID" --id "$CONFIG_ID"
  fi
}

function wait_for_deployment() {
  while true; do
    # Retrieve the configuration
    STATE=$(get_deployment_state)

    # If the state is "deployed" or "deploying_failed", exit the loop
    if [[ "$STATE" == "deployed" || "$STATE" == "deploying_failed" || "$STATE" == "deleting" || "$STATE" == "deleting_failed" ]]; then
      break
    fi

    # If the state is not "deploying", print an error message and exit
    if [[ "$STATE" != "deploying" ]]; then
      echo "Error: Unexpected state $STATE"
      exit 1
    fi

    # Sleep for a few seconds before checking the state again
    sleep 10
    keep_iam_session_active
  done
}

function die()
{
  local message=$1
  local exit_code=${2-1}
  echo >&2 -e "$message"
  exit "$exit_code"
}

function keep_iam_session_active()
{
  ibmcloud iam oauth-tokens > /dev/null
}

function validate_and_deploy()
{
  validate_config
  wait_for_validation
  approve_config
  deploy_config
  wait_for_deployment
}

parse_params "$@"
get_config_ids

# Run base config + key management first
for CONFIG_ID in "${CONFIG_IDS[@]:0:2}"; do
  validate_and_deploy
done


# Run secret manager, security compliance, observability, and WatsonX SaaS services in parallel
parallel_configs=("${CONFIG_IDS[2]}" "${CONFIG_IDS[3]}" "${CONFIG_IDS[4]}" "${CONFIG_IDS[5]}")
for CONFIG_ID in "${parallel_configs[@]}"; do
  (
    validate_and_deploy
  ) &
done
wait

# Run ALM + RAG DA at the end
for CONFIG_ID in "${CONFIG_IDS[@]:6}"; do
  validate_and_deploy
done
