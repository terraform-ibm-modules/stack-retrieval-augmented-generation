# Retrieval Augmented Generation Pattern for Watsonx on IBM Cloud

The following [deployable architecture](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da#what-is-da) automates the deployment of a sample GenAI Pattern on IBM Cloud, including all underlying IBM Cloud infrastructure. This architecture implements the best practices for Watsonx GenAI Pattern deployment on IBM Cloud, as described in the [reference architecture](https://cloud.ibm.com/docs/pattern-genai-rag?topic=pattern-genai-rag-genai-pattern).

This deployable architecture provides a comprehensive foundation for trust, observability, security, and regulatory compliance by configuring the IBM Cloud account to align with compliance settings, deploying key and secret management services, and deploying the infrastructure to support CI/CD/CC pipelines for secure application lifecycle management. These pipelines facilitate the deployment of the application, vulnerability checks, and auditability, ensuring a secure and trustworthy deployment of Generative AI applications on IBM Cloud.

# Objective and Benefits

This deployable architecture is designed to showcase a fully automated deployment of a retrieval augmented generation application through IBM Cloud Project, providing a flexible and customizable foundation for your own Watson-based application deployments on IBM Cloud. This architecture deploys the following [sample application](https://github.com/IBM/gen-ai-rag-watsonx-sample-application) by default.

By leveraging this architecture, you can accelerate your deployment and tailor it to meet your unique business needs and enterprise goals.

By using this architecture, you can:

* Establish Trust: The architecture ensures trust by configuring the IBM Cloud account to align with compliance settings as defined in the [Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-about) framework.
* Ensure Observability: The architecture provides observability by deploying services such as IBM Log Analysis, IBM Monitoring, IBM Activity Tracker, and log retention through Cloud Object Storage buckets.
* Implement Security: The architecture ensures security by deploying IBM Key Protect and IBM Secrets Manager.
* Achieve Regulatory Compliance: The architecture ensures regulatory compliance by implementing CI/CD/CC pipelines, along with IBM Security Compliance Center (SCC) for secure application lifecycle management.


# Deployment Details

To deploy this architecture, follow these steps.

## 1. Prerequisites

Before deploying the deployable architecture, ensure you have:

* Created an API key in the target account with sufficient permissions. The target account is the account that will be hosting the resources deployed by this deployable architecture. See [instructions](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui) Note the API key, as it will be used later. On evaluation environments, you may simply grant `Administrator` role on `IAM Identity Service`, `All Identity and Access enabled services` and `All Account Management` services. If you need to narrow down further access, for a production environment for instance, the minimum level of permissions is indicated in the [Permission tab](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52-global#permissions) of the deployable architecture.
* (Recommended to ensure successful sample app deployment) Created or have access to a signing key, which is the base64 key obtained from `gpg --gen-key` (if not generated before or expired) and then exported via `gpg --export-secret-key <Email Address> | base64` command. See the [devsecops image signing page](https://cloud.ibm.com/docs/devsecops?topic=devsecops-devsecops-image-signing#cd-devsecops-gpg-export) for details. Keep note of the key for later. The signing key is not required to deploy all of the Cloud resources created by this deployable architecture, but is necessary to get the automation to build and deploy the sample application.
* (Optional) Installed the IBM Cloud CLI's Project add-on using the `ibmcloud plugin install project` command. More information is available [here](https://cloud.ibm.com/docs/cli?topic=cli-projects-cli).

Ensure that you are familiar with the "Important Deployment Considerations" located at the bottom of this document.

## 2. Deploy the Stack in a New Project from Catalog

* Locate the [tile](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52-global) for the Deployable Architecture in the IBM Cloud Catalog.
* Click the "Add to project" button.

    ![image](./images/min/1-catalog.png)

* Select "Create new" and input IBM Cloud Project details.
   - Name and description. eg: "Retrieval Augmented Generation Pattern"
   - Region and resource group for the project. Note that this is the region and resource group where the runtime (IBM Cloud Schematics) executiong the automation code is located. You can still deploy the resources to any region, any resource group, and any account.
   - Configuration name - for example: "dev" or "prod".

        ![project](./images/min/2-project.png)

* Click "Add" to complete.

## 3. Set the Input Configuration for the Stack

After completing `Step 2 - Deploy the Stack in a New Project from Catalog`, you are directed to a page allowing you to enter the configuration for you deployment:
* Under Security -> Authentication, enter the API Key from the prereqs in the `api_key` field.
* Under Required, input the signing key
* Under Optional, input `signing_key` field. This is recommended by not necessary to be able to deploy the Cloud resources. It is necessary to enable the building and deployment of the sample app however.

You may explore the other available inputs, such as the region and resource group name (under optional tab), leave them as is, or modify them as needed.

![inputs](./images/min/3-inputs.png)

Once ready, click the "Save" button at the top of the screen.

## 4. Deploy the Architecture

Navigate to the project deployment view by clicking the project name in the breadcrumb menu.

![menu](./images/min/4-bread.png)


You should be directed to a screen looking like:

![validate](./images/min/5-validate.png)

Two approaches to deploy the architecture:
1. Through the UI
2. Automated - the script `stackDeploy.py` is provided. Further details on the script can be found in the [Stack Deployment Script](#stack-deployment-script) section.

### Approach 1: Deployment through the UI

1. Click on validate

    ![validate button](./images/min/5b-validate.png)

2. Wait for validation

    ![validation](./images/min/6-validation.png)

3. Approve and click the deploy button

    ![deploy](./images/min/7-deploy.png)

4. Wait for deployment

5. Repeat step 1 for the next configuration in the architecture. Note that as you progress in deploying the initial base configuration, you will be given the option to validate and deploy multiple configuration in parallel.

### Approach 2: Run stackDeploy.py

* Clone the repository at https://github.com/terraform-ibm-modules/stack-retrieval-augmented-generation/tree/main
* Ensure you are logged in to the account containing the Cloud project with the stack using `ibmcloud login`.
* Execute `stackDeploy.py` with the project name, stack name, and optional configuration name pattern.
* Further details on the script can be found in the [Stack Deployment Script](#stack-deployment-script) section.

Example - Process all configurations in the project:
```bash
python stackDeploy.py --project_name my-test-project --stack_name dev --config_order "config1|config2|config3"
```

Tips: If deployment fail for one of the configuration, you may re-run the script as is. It will skip existing installed configurations and continue where it last failed. Ensure to use the `--skip_stack_inputs` flag to avoid re-setting the stack inputs.

## 5. Post deployment steps

At this point, the infrastructure has been successfully deployed in the target account, and the initial build of the sample application has started in the newly-provisioned DevOps service.

### Monitoring the Build and Deployment

To monitor the build and deployment of the application, follow these steps:
1. **Access the DevOps Toolchains View**: Navigate to the [DevOps / Toolchains view](https://cloud.ibm.com/devops/toolchains) in the target account.
2. **Select the Resource Group and Region**: Choose the resource group and region where the infrastructure was deployed. The resource group name is based on the prefix and resource_group_name inputs of the deployable architecture.
3. **Select the Toolchain**: Select "RAG Sample App-CI-Toolchain"
    ![toolchain](./images/min/8-toolchain.png)
4. **Access the Delivery Pipeline**: In the toolchain view, select ci-pipeline under Delivery pipeline
    ![toolchain](./images/min/9-pipeline.png)
5. **View the CI Pipeline Status**: The current status of the CI pipeline execution can be found under the "rag-webhook-trigger" section.

### Verifying the Application Deployment

Once the initial run of the CI pipeline complete, you should be able to view the application running in the created [Code Engine project](https://cloud.ibm.com/codeengine/projects).


### Enabling Watson Assistant

After the application has been built and is running in Code Engine, there are additional steps specific to the sample app that need to be completed to fully enable Watson Assistant in the app. To complete the installation, follow the steps outlined in the [application README.md file](https://github.com/IBM/gen-ai-rag-watsonx-sample-application/blob/main/artifacts/artifacts-README.md).


## 6. Important Deployment Considerations

### API Key Requirements

The deployable architecture can only be deployed with an API Key associated with a user. It is not compatible with API Keys associated with a serviceId. Additionally, it cannot be deployed using the Project trusted profile support.

### Known UI Issue: "Unable to validate your configuration"

After approving the configuration, you may encounter an error message stating "Unable to validate your configuration". This is a known UI issue that can be resolved by simply **refreshing your browser window**. This will allow you to continue with the deployment process.

### Using the ./deploy-many.sh Script

The provided ./deploy-many.sh script is designed to deploy the stack of configurations as provided out of the box. If you make any changes to the stack definition in your project, besides specifying inputs, you should deploy your version through the Project UI instead of using the script.

# Stack Deployment Script
This script is used to validate, approve, and deploy configurations for a project in IBM Cloud. It can also undeploy configurations if needed.

### Prerequisites
 - Python 3
 - IBM Cloud CLI
 - IBM Cloud Project plugin

### Usage
Clone the repository and navigate to the directory containing the script.

Set the necessary environment variables, default variable is `IBMCLOUD_API_KEY` but this can be configured in the config file.:
```bash
export IBMCLOUD_API_KEY=<your_ibmcloud_api_key>
```
Run the script:
```bash
python stackDeploy.py --project_name <project_name> --stack_name <stack_name> --config_order <config_order>
```
Replace <project_name>, <stack_name>, and <config_order> with your specific values.

The script will deploy the configurations in the order specified in the config_order argument.

If using the `--parallel` flag, the script will attempt to deploy the configurations in parallel if possible. It will attempt to deploy prerequisites first, then deploy the remaining configurations in parallel. If a configuration has a dependency on another configuration, it will wait for the dependency to complete before deploying.
**NOTE:** Use parallel with caution, I always works on a fresh deployment, but it could run with unexpected results if existing configurations are in unexpected states. If in doubt, do not use parallel.


### Undeploy
To undeploy a stack, run the script with the `--undeploy` flag:
```python stackDeploy.py --project_name <project_name> --stack_name <stack_name> --config_order <config_order> --undeploy```
The script will undeploy in reverse order of the config_order argument sequentially, as the reverse order is the safest way to undeploy configurations.

### Arguments
Arguments will take precedence over settings in the config file.
 - `-p <PROJECT_NAME>, --project_name <PROJECT_NAME>`: The project name (can be set in the config file)
 - `-s <STACK_NAME>, --stack_name <STACK_NAME>`: The stack name (can be set in the config file)
 - `-o <CONFIG_ORDER>, --config_order <CONFIG_ORDER>`: The config names in order to be deployed in the format "config1|config2|config3" (can be set in the config file)
 - `--stack_def_path <STACK_DEF_PATH>`: The path to the stack definition json file (can be set in the config file)
 - `--stack_inputs <STACK_INPUTS>`: Stack inputs as json string {"inputs":{"input1":"value1", "input2":"value2"}} (can be set in the config file)
 - `--stack_api_key_env <STACK_API_KEY_ENV>`: The environment variable name for the stack api key to deploy with. Default `IBMCLOUD_API_KEY` (can be set in the config file)
 - `-c <CONFIG_JSON_PATH>, --config_json_path <CONFIG_JSON_PATH>`: The path to the config json file
 - `--skip_stack_inputs`: Skip setting stack inputs
 - `-u, --undeploy`: Undeploy the stack
 - `--debug`: Enable debug mode
 - `--parallel`: Deploy configurations in parallel
 - `--help`: Show help message

### Sample Config File
```json
{
    "project_name": "my_project",
    "stack_name": "my_stack",
    "config_order": [
        "config1",
        "config2",
        "config3"],
    "stack_def_path": "stack_definition.json",
    "stack_inputs": {
        "input1":"value1",
        "input2":"value2",
        "ibmcloud_api_key": "API_KEY"
    },
    "api_key_env_var": "IBMCLOUD_API_KEY"
}
```
- `project_name`: The name of your project.
- `stack_name`: The name of your stack.
- `config_order`: An array of configuration names in the order they should be deployed.
- `stack_def_path`: The path to the stack definition JSON file.
- `stack_inputs`: A dictionary of stack inputs. NOTE: if a key is set to `API_KEY` it will be replaced with the value of the `stack_api_key_env` environment variable.
- `config_json_path`: The path to the configuration JSON file.
- `stack_api_key_env`: The environment variable name for the stack API key to deploy with.


### Troubleshooting
If you encounter any errors, check the logs for detailed error messages. If the error is related to a specific configuration, the error message will include the configuration ID.
The debug flag can be used to print additional information to the console.

If a failure occurs sometimes running the deployment script again will resolve the issue. Ensure the `--skip_stack_inputs` flag is enabled and the script will skip configurations that have already been deployed.
