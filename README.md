# Retrieval Augmented Generation Pattern for Watsonx on IBM Cloud

The following [deployable architecture](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da#what-is-da) automates the deployment of a sample GenAI Pattern on IBM Cloud, including all underlying infrastructure. This architecture implements the best practices for Watsonx GenAI Pattern deployment on IBM Cloud, as described in the [reference architecture](https://cloud.ibm.com/docs/pattern-genai-rag?topic=pattern-genai-rag-genai-pattern).

# Deployment Details

To run the full stack, follow these steps. These steps will be updated as development progresses on the stack and underlying deployable architectures.

## 1. Deploy the Stack in a New Project from Catalog

Catalog URL: https://cloud.ibm.com/catalog/7df1e4ca-d54c-4fd0-82ce-3d13247308cd/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52?bss_account=9f9af00a96104f49b6509aa715f9d6a5

Click the "Add to Project" button and select "Create in new project."

## 2. Prerequisites in Target Account

Before deploying the stack, ensure you have:

* Created an API key in the target account with sufficient permissions. Note the API key, as it will be used later. For now, grant it admin privileges. The exact permissions required will be refined in future versions.
* Installed the IBM Cloud CLI's Project add-on using the `ibmcloud plugin install project` command. More information is available here: https://cloud.ibm.com/docs/cli?topic=cli-projects-cli

## 3. Set the Input Configuration for the Stack

* Clone this repository locally.
* Create a file named ".def.json" with the following content:

**Important**:
* Ensure the region is either us-south or eu-de, as Watsonx can only be deployed in those two locations for now.
* Ensure that the prefix is globally unique. It is used for the container registry namespace (which needs to be globally unique) in this alpha version.
* If specifying `existing_secrets_manager_crn`, the `ibmcloud_api_key` that is passed as an input must have the documented read and write access to the instance.
* If specifying `existing_secrets_manager_crn`, ensure that the default security group does not contain secrets named `signing-key` and `ibmcloud-api-key`. The RAG DA currently always attempts to create a secret with those names (temporary issue - to be fixed).
* The signing key is the base64 key obtained from `gpg --gen-key` (if not generated before or expired) and then exported via `gpg --export-secret-key <Email Address> | base64` command. See https://cloud.ibm.com/docs/devsecops?topic=devsecops-devsecops-image-signing#cd-devsecops-gpg-export for details.

```json
{
    "inputs": {
        "prefix": "<prefix for resources name - ensure unique>",
        "ibmcloud_api_key": "<API Key of the target account with sufficient permissions>",
        "resource_group_name": "<target resource group - name of a new resource group that the stack will create>",
        "region": "<region where all resources are deployed>",
        "sample_app_git_url": "https://github.com/IBM/gen-ai-rag-watsonx-sample-application",
        "watsonx_admin_api_key": "<optional - admin key to use for Watsonx if different from ibmcloud_api_key>",
        "signing_key": "signing key used to sign build artifacts",
        "existing_secrets_manager_crn": "<optional> - reuse an existing secret manager instance",
        "enable_platform_logs_metrics": "<optional> - set to true to enable observability instance to capture regional logs"
    }
}
```

Example:
```json
{
    "inputs": {
        "prefix": "0418",
        "ibmcloud_api_key": "<your api key>",
        "resource_group_name": "stack-service-rg",
        "region": "eu-de",
        "sample_app_git_url": "https://github.com/IBM/gen-ai-rag-watsonx-sample-application",
        "watsonx_admin_api_key": "<optional - admin key to use for Watsonx if different from ibmcloud_api_key>",
        "signing_key": "signing key used to sign build artifacts",
        "enable_platform_logs_metrics": "false",
        "existing_secrets_manager_crn": "crn:v1:bluemix:public:secrets-manager:us-south:a/190c293e9fda4c6684b5acf4b17871b8:14580411-4fa2-42d3-af3f-ab7fc6371b6d::"
    }
}
```


## 4. Run ./deploy-many.sh

* Ensure you are logged in to the account containing the Cloud project with the stack using `ibmcloud login --sso`.
* Execute `./deploy-many.sh` with the project name, stack name (name of the configuration given when deploying the tile), and optional configuration name pattern. The selected non-stack configurations will be processed by their name in alphabetical order. Using the configuration name pattern (regex can be used - make sure to enclose it in quotes), you can choose which configurations are deployed.

Example 1 - Update stack inputs for stack configuration `RAG` and process all non-stack configurations in the project:
```bash
./deploy-many.sh my-test-project RAG
```

Example 2 - Update stack inputs and process some configurations in the project:
```bash
./deploy-many.sh my-test-project RAG 'RAG-1|RAG-4|RAG-5'
```

Example 3 - Simulate updating stack inputs and validating some configurations in the project in dry-run mode (no changes or actual validation or deployments are done):
```bash
DRY_RUN=true ./deploy-many.sh my-test-project RAG 'RAG-1|RAG-4|RAG-5'
```

Tips: If deployment fail in one of the DA, you may re-run the script as is. It will skip existing installed configuration.
