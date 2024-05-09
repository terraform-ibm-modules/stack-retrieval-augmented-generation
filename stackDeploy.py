#!/usr/bin/env python3

import argparse
import os
import subprocess
import json
import time
import logging
import concurrent.futures

from enum import Enum


class DeploymentError(Exception):
    pass


class ValidationError(Exception):
    pass


class ApprovalError(Exception):
    pass


class ProjectNotFoundError(Exception):
    pass


class ConfigNotFoundError(Exception):
    pass


class StackNotFoundError(Exception):
    pass


class State(Enum):
    VALIDATED = "validated"
    DEPLOYED = "deployed"
    DRAFT = "draft"
    DEPLOYING_FAILED = "deploying_failed"
    APPROVED = "approved"
    DELETING = "deleting"
    DELETING_FAILED = "deleting_failed"
    DEPLOYING = "deploying"
    VALIDATING = "validating"
    DELETED = "deleted"
    DISCARDED = "discarded"
    SUPERSEDED = "superseded"
    UNDEPLOYING = "undeploying"
    UNDEPLOYING_FAILED = "undeploying_failed"
    VALIDATING_FAILED = "validating_failed"
    APPLIED = "applied"
    APPLY_FAILED = "apply_failed"
    UNKNOWN = "unknown" # unknown state, custom not in the API


class StateCode(Enum):
    AWAITING_VALIDATION = "awaiting_validation"
    AWAITING_PREREQUISITE = "awaiting_prerequisite"
    AWAITING_INPUT = "awaiting_input"
    AWAITING_MEMBER_DEPLOYMENT = "awaiting_member_deployment"
    AWAITING_STACK_SETUP = "awaiting_stack_setup"
    AWAITING_APPROVAL = "awaiting_approval"
    AWAITING_DEPLOYMENT = "awaiting_deployment"
    AWAITING_DELETION = "awaiting_deletion"
    AWAITING_UNDEPLOYMENT = "awaiting_undeployment"
    UNKOWN = "unknown"  # unknown state, custom not in the API


def string_to_state(state_str: str) -> State:
    try:
        return State[state_str.upper()]
    except KeyError:
        raise ValueError(f"Invalid state: {state_str}")


def string_to_state_code(state_code_str: str) -> StateCode:
    try:
        return StateCode[state_code_str.upper()]
    except KeyError:
        raise ValueError(f"Invalid state code: {state_code_str}")


def parse_params() -> (str, str, list[str], str, str, str, bool, bool, bool, bool):
    """
    Parse command line parameters.

    Returns:
        Tuple containing:
            project name, stack name, config order,
            stack definition path, stack inputs, api key environment variable name,
            undeploy flag, skip stack inputs flag, stack definition update flag, debug flag
    """
    parser = argparse.ArgumentParser(description='Update and deploy stack, or undeploy. Arguments override config '
                                                 'json file.')
    parser.add_argument('-p', '--project_name', type=str, help='The project name', default=None)
    parser.add_argument('-s', '--stack_name', type=str, help='The stack name', default=None)
    parser.add_argument('-o', '--config_order', type=str,
                        default=None,
                        help='The config names in order to be deployed in the format "config1|config2|config3"')
    parser.add_argument('--stack_def_path', type=str, help='The path to the stack definition json file',
                        default="stack_definition.json")
    # alternatively, config from json file
    parser.add_argument('-c', '--config_json_path', type=str,
                        default=None, help='The path to the config json file')
    parser.add_argument('-u', '--undeploy', action='store_true', help='Undeploy the stack')
    parser.add_argument('--stack_inputs', type=str,
                        help='Stack inputs as json string {"inputs":{"input1":"value1", "input2":"value2"}}',
                        default=None)
    parser.add_argument('--stack_api_key_env', type=str, help='The environment variable name for the stack api key',
                        default='IBMCLOUD_API_KEY')
    parser.add_argument('--skip_stack_inputs', action='store_true', help='Skip setting stack inputs')
    parser.add_argument('--stack_definition_update', action='store_true', help='Updating stack definition')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    args = parser.parse_args()
    project_name = args.project_name
    stack_name = args.stack_name
    stack_inputs = None
    if args.stack_inputs:
        try:
            stack_inputs = json.loads(args.stack_inputs)
        except json.JSONDecodeError:
            logging.error('Invalid stack inputs json')
            exit(1)
    config_order = args.config_order
    if config_order:
        config_order = config_order.split('|')
    debug = args.debug
    stack_def_path = args.stack_def_path
    api_key_env = None
    # load config from json file
    # { "project_name": "project_name", "stack_name": "stack_name", "config_order": ["config1", "config2"] }
    if args.config_json_path:
        try:
            with open(args.config_json_path) as f:
                config = json.load(f)
        except FileNotFoundError:
            logging.error(f'Config json file not found at: {args.config_json_path}')
            exit(1)
        except json.JSONDecodeError:
            logging.error(f'Invalid config json: {args.config_json_path}')
            exit(1)
        if not project_name:
            project_name = config.get('project_name', '')
        if not stack_name:
            stack_name = config.get('stack_name', '')
        if not config_order:
            config_order = config.get('config_order', [])
        stack_def_path = config.get('stack_def_path', stack_def_path)
        if not stack_inputs:
            stack_inputs = config.get('stack_inputs', '')
        api_key_env = config.get('stack_api_key_env', api_key_env)

    if not api_key_env:
        api_key_env = args.stack_api_key_env

    # check api key env exists
    if os.environ.get(api_key_env) is None:
        logging.error(f'{api_key_env} environment variable must be set')
        exit(1)

    # check stack_def_path exists
    if not stack_def_path or not os.path.exists(stack_def_path):
        logging.error('Stack definition path must be provided and exist')
        # print argument help
        parser.print_help()
        exit(1)

    # error if project name, stack name or config name pattern is not provided
    if not project_name or not stack_name or not config_order:
        logging.error('Project name, stack name and config order must be provided')
        # print argument help
        parser.print_help()
        exit(1)

    return (project_name, stack_name, config_order, stack_def_path, stack_inputs, api_key_env,
            args.undeploy, args.skip_stack_inputs, args.stack_definition_update, debug)


def run_command(command: str) -> (str, str):
    """
    Run a shell command.

    Args:
        command: The command to run.

    Returns:
        The stdout and stderr output of the command.
    """
    logging.debug(f'Running command: {command}')
    retries = 5

    for i in range(retries):
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   universal_newlines=True)
        output, error = process.communicate()
        # retry on tls handshake timeout
        if 'tls handshake timeout' in error.lower() or 'tls handshake timeout' in output.lower():
            logging.error(f'Timeout error executing command {command}:\n'
                          f'Output: {output}\nError:{error}\nretrying in 30 seconds, attempt {i + 1}/{retries}')
            time.sleep(30)
        elif process.returncode == 0:
            return output, error
        else:
            logging.error(f'error executing command: {command}')
            logging.error(f'Output: {output}\nError: {error}')
            return output, error


def check_require_tools() -> dict:
    """
    Check required tools.

    Returns:
        dict: Missing tools and plugins.
    """
    tools = ['ibmcloud']
    ibmcloud_plugins = ['project']
    missing = {'tools': [], 'plugins': []}  # use strings 'tools' and 'plugins' as keys
    for tool in tools:
        try:
            result = run_command(f'which {tool}')
            logging.debug(f'{tool} path: {result}')
        except FileNotFoundError:
            missing['tools'].append(tool)
    for plugin in ibmcloud_plugins:
        try:
            result = run_command(f'ibmcloud plugin show {plugin}')
            logging.debug(f'{plugin} plugin: {result}')
        except subprocess.CalledProcessError:
            missing['plugins'].append(plugin)

    return missing


def is_logged_in() -> bool:
    """
    Check if user is logged in.

    Returns:
        bool: True if user is logged in, False otherwise.
    """
    try:
        result, err = run_command('ibmcloud account show')
        logging.debug(f'Account show: {result}')
        if 'Not logged in' in result or 'Not logged in' in err:
            return False
        return True
    except subprocess.CalledProcessError:
        return False


def login_ibmcloud(api_key_env: str) -> None:
    """
    Login to IBM Cloud.

    Args:
        api_key_env (str): API key environment variable name.
    """

    command = f'ibmcloud login --apikey {os.environ.get(api_key_env)} --no-region'
    output, err = run_command(command)
    if err:
        logging.error(f'Error: {err}')
        exit(1)
    logging.debug(f'Login output: {output}')


def get_project_id(project_name: str) -> str:
    """
    Get project ID.

    Args:
        project_name (str): Project name.

    Returns:
        str: Project ID.
    """
    command = f'ibmcloud project list --all-pages --output json'
    output, err = run_command(command)
    if err:
        raise Exception(f'Error: {err}')
    logging.debug(f'Project list: {output}')
    data = json.loads(output)
    projects = data.get('projects', [])
    for project in projects:
        # Check if 'metadata' exists in the project dictionary
        if 'definition' in project and project['definition']['name'] == project_name:
            logging.debug(f'Project ID for {project_name} found: {project["id"]}')
            return project['id']
    raise ProjectNotFoundError(f'Project {project_name} not found')


def get_project_configs(project_id: str) -> list[dict]:
    """
    Get project configs.

    Args:
        project_id (str): Project ID.

    Returns:
        list[dict]: List of project configs.
    """
    command = f'ibmcloud project configs --project-id {project_id} --output json'
    output, err = run_command(command)
    if err:
        raise Exception(f'Error: {err}')
    logging.debug(f'Project configs: {output}')
    data = json.loads(output)
    return data.get('configs', [])


def get_stack_id(project_id: str, stack_name: str) -> str:
    """
    Get stack ID.

    Args:
        project_id (str): Project ID.
        stack_name (str): Stack name.

    Returns:
        str: Stack ID.
    """
    project_configs = get_project_configs(project_id)
    for config in project_configs:
        if 'definition' in config and config['definition']['name'] == stack_name:
            logging.debug(f'Stack ID for {stack_name} found: {config["id"]}')
            return config['id']
    raise StackNotFoundError(f'Stack {stack_name} not found')


def get_config_ids(project_id: str, stack_name: str, config_order: list[str]) -> list[dict]:
    """
    Get config IDs.

    Args:
        project_id (str): Project ID.
        stack_name (str): Stack name.
        config_order (list[str]): Config order.

    Returns:
        list[dict]: List of config IDs.
    """
    project_configs = get_project_configs(project_id)
    configs = []
    for config in project_configs:
        # ignore if stack
        if config['deployment_model'] == 'stack':
            logging.debug(f'Skipping stack:\n{config}')
            continue
        logging.debug(f'Checking Config:\n{config}')
        # Check if 'definition' exists in the config dictionary
        # when deploying from tile the config name is in the format stack_name-config_name so strip the prefix
        if ('definition' in config and
                (config['definition']['name'] in config_order or
                 str(config['definition']['name']).strip(f"{stack_name}-") in config_order)):
            cur_config = {config['definition']['name']: {"locator_id": config['definition']['locator_id'],
                                                         "config_id": config['id']}}
            # only add unique configs
            if cur_config not in configs:
                configs.append(cur_config)
    if len(configs) != len(config_order):
        # show missing configs
        for config in config_order:
            if config not in configs and f"{stack_name}-{config}" not in configs:
                logging.error(f'Config {config} not found')
        if len(configs) < len(config_order):
            logging.error(f'Not all configs found, expected: {config_order}\nFound: {configs}')
        if len(configs) > len(config_order):
            logging.error(f'Too many configs found, expected: {config_order}\nFound: {configs}')
        raise ConfigNotFoundError('Config not found')

    # sort configs based on config_order, the stack name may be included in the config name
    sorted_confs = []
    # configs  =  [{'config1': {'locator_id': '12345.1234', 'catalog_id':'12345', 'config_id': '1234'}}]
    for conf in config_order:
        if conf not in configs:
            # assume the config name is in the format stack_name-config_name
            conf = f"{stack_name}-{conf}"
        sorted_confs.append(find_dict_with_key(configs, conf))
    logging.debug(f'Config IDs: {sorted_confs}')
    return sorted_confs


def find_dict_with_key(list_of_dicts: list[dict], key: str) -> dict | None:
    """
    Find the first dictionary in a list that contains a specified key.

    Args:
        list_of_dicts (list[dict]): The list of dictionaries to search.
        key (str): The key to search for.

    Returns:
        dict: The first dictionary that contains the key. If no dictionary contains the key, returns None.
    """
    for dictionary in list_of_dicts:
        if key in dictionary:
            return dictionary
    return None


def update_stack_definition(project_id: str, stack_id: str, stack_def_path: str) -> None:
    """
    Update stack definition.

    Args:
        project_id (str): Project ID.
        stack_id (str): Stack ID.
        stack_def_path (str): Stack definition path.
    """

    command = (f'ibmcloud project config-update --project-id {project_id} '
               f'--id {stack_id} --definition @{stack_def_path}')
    output, err = run_command(command)
    if err:
        logging.error(f'Error: {err}')
        exit(1)
    logging.debug(f'Stack definition updated: {output}')


def set_stack_inputs(project_id: str, stack_id: str, stack_inputs: dict, api_key_env: str) -> None:
    """
    Set stack inputs.

    Args:
        project_id (str): Project ID.
        stack_id (str): Stack ID.
        stack_inputs (dict): Stack inputs.
        api_key_env (str): API key environment variable name.
    """
    # if input dict key has value API_KEY replace with the value from the environment variable
    for key, value in stack_inputs.items():
        if value == 'API_KEY':
            stack_inputs[key] = os.environ.get(api_key_env)

    stack_input_json = json.dumps(stack_inputs)
    command = (f'ibmcloud project config-update --project-id {project_id} '
               f'--id {stack_id} --definition-inputs \'{stack_input_json}\'')
    output, err = run_command(command)
    if err:
        logging.error(f'Error: {err}')
        exit(1)
    logging.debug(f'Stack inputs updated: {output}')


def set_authorization(project_id: str, stack_id: str, api_key_env: str) -> None:
    """
    Set authorization.

    Args:
        project_id (str): Project ID.
        stack_id (str): Stack ID.
        api_key_env (str): API key environment variable name.
    """
    auth_json = json.dumps({"method": "api_key",
                            "api_key": os.environ.get(api_key_env)})
    command = (f'ibmcloud project config-update --project-id {project_id} '
               f'--id {stack_id} --definition-authorizations \'{auth_json}\'')
    output, err = run_command(command)
    if err:
        logging.error(f'Error: {err}')
        exit(1)
    logging.debug(f'Authorization updated')


def validate_config(project_id: str, config_id: str, timeout: str = "30m") -> None:
    """
    Validate config.

    Args:
        project_id (str): Project ID.
        config_id (str): Config ID.
        timeout (str): Timeout for validation.
    """
    start_time = time.time()
    end_time = start_time + parse_time(timeout)
    state = get_config_state(project_id, config_id)
    config_name = get_config_name(project_id, config_id)
    if state == State.DEPLOYED or state == State.DEPLOYING_FAILED or state == State.VALIDATED or state == State.APPROVED:
        logging.info(f'[{config_name}] Already Validated Skipping: {config_id}')
        return
    if state != State.VALIDATED:
        command = f'ibmcloud project config-validate --project-id {project_id} --id {config_id}'
        output, err = run_command(command)
        if err:
            raise Exception(f'Error: {err}')

        logging.info(f'[{config_name}] Started validation for config {config_id}')
        state = get_config_state(project_id, config_id)
        while state == State.VALIDATING and time.time() < end_time:
            time.sleep(30)
            state = get_config_state(project_id, config_id)
            logging.info(f'[{config_name}] Validating {config_id}...')
            logging.debug(f'[{config_name}] Validation state: {state}')

        state = get_config_state(project_id, config_id)
        if state != State.VALIDATED:
            raise ValidationError(f'[{config_name}] Validation failed for config {config_id}')
    logging.debug(f'[{config_name}] Config validated successfully: {config_id}')


def get_config_state(project_id: str, config_id: str) -> State:
    """
    Get the state of a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.

    Returns:
        The state of the config.
    """
    command = f'ibmcloud project config --project-id {project_id} --id {config_id} --output json'
    output, err = run_command(command)
    if err:
        raise Exception(f'Error: {err}')
    logging.debug(f'Config state: {output}')
    data = json.loads(output)
    state = data.get('state', '')
    if state == '':
        logging.error(f'state not found for config {config_id}\n{data}')
        return State.UNKNOWN
    return string_to_state(state)


def get_config_state_code(project_id: str, config_id: str) -> StateCode:
    """
    Get the state code of a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.

    Returns:
        The state code of the config.
    """
    command = f'ibmcloud project config --project-id {project_id} --id {config_id} --output json'
    output, err = run_command(command)
    if err:
        raise Exception(f'Error: {err}')
    logging.debug(f'Config state: {output}')
    data = json.loads(output)
    state = data.get('state_code', '')
    if state == '':
        return StateCode.UNKOWN
    return string_to_state_code(state)


def get_config_name(project_id: str, config_id: str) -> str:
    """
    Get the name of a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.

    Returns:
        The name of the config.
    """
    command = f'ibmcloud project config --project-id {project_id} --id {config_id} --output json'
    output, err = run_command(command)
    if err:
        raise Exception(f'Error: {err}')
    logging.debug(f'Config name: {output}')
    data = json.loads(output)
    name = data.get('definition', {}).get('name', 'UNKNOWN')
    return name


def get_config_deployed_state(project_id: str, config_id: str) -> State:
    """
    Get the deployed state of a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.

    Returns:
        The deployed state of the config.
    """
    command = f'ibmcloud project config --project-id {project_id} --id {config_id} --output json'
    output, err = run_command(command)
    if err:
        raise Exception(f'Error: {err}')
    logging.debug(f'Config deployed: {output}')
    data = json.loads(output)
    state = data.get('deployed_version', {}).get('state', '')
    if state == '':
        # if not deployed get the current config state instead
        return get_config_state(project_id, config_id)
    return string_to_state(state)


def approve_config(project_id: str, config_id: str) -> None:
    """
    Approve a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.
    """

    try:
        state = get_config_state(project_id, config_id)
        config_name = get_config_name(project_id, config_id)
    except Exception as e:
        raise Exception(f'Error: {e}')
    if state == State.DEPLOYED or state == State.DEPLOYING_FAILED:
        logging.info(f'[{config_name}] Already Approved Skipping: {config_id}')
        return
        # only approve if not already approved and validated
    if state != State.APPROVED and state == State.VALIDATED:
        logging.info(f'[{config_name}] Approving config: {config_id}')
        command = (f'ibmcloud project config-approve --project-id {project_id} '
                   f'--id {config_id} --comment "Approved by script"')
        output, err = run_command(command)
        if err:
            raise ApprovalError(f'[{config_name}] Error approving config {config_id}, error: {err}')
        state = get_config_state(project_id, config_id)
        start_time = time.time()
        end_time = start_time + parse_time("5m")
        while state != State.APPROVED and time.time() < end_time:
            time.sleep(5)
            state = get_config_state(project_id, config_id)
            logging.info(f'[{config_name}] Approving {config_id}...')
            logging.debug(f'[{config_name}] Approve {config_id} state: {state}')
        state = get_config_state(project_id, config_id)
        if state != State.APPROVED:
            raise ApprovalError(f'[{config_name}] Approval failed for config {config_id}')
        logging.info(f'[{config_name}] Config approved: {config_id}')
    elif state == State.APPROVED:
        logging.info(f'[{config_name}] Config already approved: {config_id}')
    elif state != State.VALIDATED:
        raise ApprovalError(f'[{config_name}] '
                            f'Config not validated: {config_id} cannot be approved, current state: {state}')

    state = get_config_state(project_id, config_id)
    if state != State.APPROVED:
        raise ApprovalError(f'Approval failed for config {config_id}, current state: {state}')


def deploy_config(project_id: str, config_id: str, timeout: str = "2h") -> None:
    """
    Deploy a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.
    """

    start_time = time.time()
    end_time = start_time + parse_time(timeout)
    state = get_config_state(project_id, config_id)
    config_name = get_config_name(project_id, config_id)
    if state == State.APPROVED or state == State.DEPLOYING_FAILED:
        logging.info(f'[{config_name}] Deploying config: {config_id}')
        command = f'ibmcloud project config-deploy --project-id {project_id} --id {config_id}'
        output, err = run_command(command)
        if err:
            raise DeploymentError(f'[{config_name}] Error deploying config {config_id}')
        state = get_config_state(project_id, config_id)
        while state == State.DEPLOYING and time.time() < end_time:
            time.sleep(30)
            state = get_config_state(project_id, config_id)
            logging.info(f'[{config_name}] Deploying {config_id}...')
            logging.debug(f'[{config_name}] Deploy {config_id} state: {state}')

        state = get_config_state(project_id, config_id)
        if state != State.DEPLOYED:
            # TODO: lookup deployment failure reason
            raise DeploymentError(f'[{config_name}] Deployment failed for config {config_id}')
        logging.info(f'[{config_name}] Config deployed: {config_id}')
    elif state == State.DEPLOYED:
        logging.info(f'[{config_name}] Config already deployed: {config_id}')
    elif state != State.APPROVED:
        raise DeploymentError(f'[{config_name}] Config not approved: '
                              f'{config_id} cannot be deployed, current state: {state}')
    else:
        raise DeploymentError(f'[{config_name}] Config not in a state that can be deployed: '
                              f'{config_id}, current state: {state}')


def undeploy_config(project_id: str, config_id: str, timeout: str = "2h") -> None:
    """
    Undeploy a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.
    """

    start_time = time.time()
    end_time = start_time + parse_time(timeout)

    config_name = get_config_name(project_id, config_id)
    state = get_config_deployed_state(project_id, config_id)
    if state == State.DEPLOYED or state == State.DEPLOYING_FAILED or state == State.UNDEPLOYING_FAILED:
        if state != State.UNDEPLOYING:
            logging.info(f'[{config_name}] Undeploying config: {config_id}')
            command = f'ibmcloud project config-undeploy --project-id {project_id} --id {config_id}'
            output, err = run_command(command)
            if err:
                raise DeploymentError(f'[{config_name}] Error undeploying config {config_id}')
        state = get_config_deployed_state(project_id, config_id)

        while state == State.UNDEPLOYING and time.time() < end_time:
            time.sleep(30)
            state = get_config_deployed_state(project_id, config_id)
            logging.info(f'[{config_name}] Undeploying {config_id}...')
            logging.debug(f'[{config_name}] Undeploy {config_id} state: {state}')

        state = get_config_deployed_state(project_id, config_id)
        if state == State.DEPLOYED or state == State.UNDEPLOYING_FAILED:
            raise DeploymentError(f'[{config_name}] Undeployment failed for config {config_id}')
        logging.info(f'[{config_name}] Config undeployed: {config_id}')
    else:
        logging.info(f'[{config_name}] Config not deployed: {config_id} skipping undeploy, current state: {state}')


def parse_time(time_str):
    """
    Parse a time string formatted as number followed by 's' for seconds, 'm' for minutes, 'h' for hours.

    Args:
        time_str (str): The time string to parse.

    Returns:
        int: The time in seconds.
    """

    if time_str.endswith('m'):
        parsed_time = int(time_str[:-1]) * 60
    elif time_str.endswith('h'):
        parsed_time = int(time_str[:-1]) * 3600
    elif time_str.endswith('s'):
        parsed_time = int(time_str[:-1]) * 1
    else:
        #     default to seconds
        try:
            parsed_time = int(time_str) * 1
        except ValueError:
            logging.error(f'Invalid time string: {time_str}')
            exit(1)
    return parsed_time


def validate_and_deploy(project_id: str, config_id: str) -> None:
    """
    Validate and deploy a config.

    Args:
        project_id: The project ID.
        config_id: The config ID.
    """
    try:
        validate_config(project_id, config_id)
        approve_config(project_id, config_id)
        deploy_config(project_id, config_id)
    except ValidationError as verr:
        logging.error(f"Validation error: {verr}")
        raise verr
    except ApprovalError as aerr:
        logging.error(f"Approval error: {aerr}")
        raise aerr
    except DeploymentError as derr:
        logging.error(f"Deployment error: {derr}")
        raise derr
    except Exception as e:
        logging.error(f"Error occurred during validation and deployment: {e}")
        raise e


def main() -> None:
    """
    Main function.
    """
    (project_name, stack_name, config_order, stack_def_path, stack_inputs, api_key_env,
     undeploy, skip_stack_inputs, stack_def_update, debug) = parse_params()
    if debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    logging.info(f'Project name: {project_name}')
    logging.info(f'Stack name: {stack_name}')
    logging.info(f'API key environment variable: {api_key_env}')
    logging.info(f'Config order: {config_order}')
    logging.info(f'Stack definition path: {stack_def_path}')
    logging.debug(f'Stack inputs: {stack_inputs}')
    logging.info(f'Undeploy: {undeploy}')
    logging.info(f'Skip stack inputs: {skip_stack_inputs}')
    logging.info(f'Stack definition update: {stack_def_update}')
    logging.info(f'Debug: {debug}')

    missing = check_require_tools()
    if missing['tools']:
        logging.error(f'Tools not found: {missing["tools"]}')
        exit(1)
    if missing['plugins']:
        logging.error(f'IBM Cloud plugins not found: {missing["plugins"]}')
        exit(1)
    if not is_logged_in():
        login_ibmcloud(api_key_env)

    # Create a list to store error messages
    error_messages = []

    project_id = get_project_id(project_name)
    # TODO: support multiple stacks
    stack_id = get_stack_id(project_id, stack_name)
    config_ids = get_config_ids(project_id, stack_name, config_order)
    if undeploy:
        # undeploy all configs in reverse order
        for config in reversed(config_ids):
            try:
                undeploy_config(project_id, list(config.values())[0]['config_id'])
            except DeploymentError as derr:
                logging.error(f"Un-deployment error: {derr}")
                error_messages.append(str(derr))
    else:
        if stack_def_update:
            logging.info(f'Updating stack definition for stack {stack_name}')
            update_stack_definition(project_id, stack_id, stack_def_path)
        if not skip_stack_inputs and stack_inputs:
            logging.info(f'Setting stack inputs for stack {stack_name}')
            set_stack_inputs(project_id, stack_id, stack_inputs, api_key_env)
            logging.info(f'Setting authorization for stack {stack_name}')
            set_authorization(project_id, stack_id, api_key_env)
        # All configs with state_code awaiting_validation can be validated
        deployed_configs = []
        error_occurred = False
        while len(deployed_configs) < len(config_ids) and not error_occurred:
            ready_to_deploy = []
            # identify all configs that can be deployed
            for config in config_ids:
                # skip already deployed configs
                if config in deployed_configs:
                    continue
                config_name = get_config_name(project_id, list(config.values())[0]['config_id'])
                try:
                    current_state_code = get_config_state_code(project_id, list(config.values())[0]['config_id'])
                    current_state = get_config_state(project_id, list(config.values())[0]['config_id'])
                    deploy_state = get_config_deployed_state(project_id, list(config.values())[0]['config_id'])
                    if current_state == State.DEPLOYED:
                        continue
                    logging.info(f"Checking for config {config_name} ID: {list(config.values())[0]['config_id']} "
                                 f"ready for validation and deployment")
                    if ((current_state_code == StateCode.AWAITING_VALIDATION
                            and current_state == State.DRAFT
                            and deploy_state != State.DEPLOYED)
                            or current_state == State.DEPLOYING_FAILED
                            or current_state == State.VALIDATING_FAILED
                            or current_state == State.APPLY_FAILED
                            or current_state == State.APPROVED):
                        logging.info(f"Config {config_name} ID: {list(config.keys())[0]} "
                                     f"is ready for validation and deployment")
                        ready_to_deploy.append(config)
                    else:
                        logging.info(f"Config {config_name} ID: {list(config.keys())[0]} "
                                     f"is not ready for validation and deployment current state: {current_state}")
                except ValueError:
                    logging.info(f"Config {config_name} ID: {list(config.keys())[0]} "
                                 f"no state found trying to validate and deploy")
                    ready_to_deploy.append(config)
                except Exception:
                    logging.info(f"Config {config_name} ID: {list(config.keys())[0]} "
                                 f"no state found trying to validate and deploy")
                    ready_to_deploy.append(config)
            if not ready_to_deploy:
                logging.info("No configs ready for validation and deployment")
            else:
                logging.info(f"Configs ready for validation and deployment: {ready_to_deploy}")
                #  validate and deploy all configs that are ready in parallel
                with concurrent.futures.ThreadPoolExecutor() as executor:
                    futures = []
                    for config in ready_to_deploy:
                        futures.append(
                            executor.submit(validate_and_deploy, project_id, list(config.values())[0]['config_id']))
                    concurrent.futures.wait(futures)  # wait for all futures to complete
                    for future in futures:
                        if future.exception() is not None:
                            logging.error(f"Exception occurred during validation and deployment: {future.exception()}")
                            error_messages.append(str(future.exception()))
                            error_occurred = True
                            break
                        else:
                            deployed_configs.append(future.result())
    # At the end of the script, print the error messages if any
    if error_messages:
        logging.info("The following errors occurred, please see the IBM Cloud Projects UI:")
        for msg in error_messages:
            logging.error(msg)


if __name__ == "__main__":
    main()
