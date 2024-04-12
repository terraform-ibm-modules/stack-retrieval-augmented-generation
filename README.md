# Retrievel Augmented Generation (RAG) stack

To run the full stack. These steps will be updated as development progresses on the stack and underlaying DAs.

## 1. Deploy the stack in a new project from catalog

Catalog url: https://cloud.ibm.com/catalog/7df1e4ca-d54c-4fd0-82ce-3d13247308cd/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52?bss_account=9f9af00a96104f49b6509aa715f9d6a5

Click the "Add to project" button, and select create in new project.

## 2. Prereqs in target account

- Create an API key in the target account. Keep note of it. Give it admin privilege for now. Exact permissions will be narrowed down in future version.
- Create a resource group in the target account. This steps is temporary in current alpha version - resource groups will be created in the base account DA in future versions.


## 3. Set the input configuration for the stack

- Clone this repository locally - and checkout the dev branch.
- Create a file with name ".def.json" with the following content. Important: ensure region is either us-south or eu-de as watsonx can only be deployed in those 2 locations for now.

```json
{
    "inputs": {
        "prefix": "<prefix for resources name>",
        "ibmcloud_api_key": "<API Key of the target account with sufficient permissions>",
        "resource_group_name": "<target resource group - must be existing in account>",
        "region": "<region where resources are deployed>",
        "sample_app_git_url": "https://github.com/IBM/gen-ai-rag-watsonx-sample-application"
    }
}
```

Example:
```json
{
    "inputs": {
        "prefix": "0410",
        "ibmcloud_api_key": "<your api key>",
        "resource_group_name": "0411-stack-service-rg",
        "region": "eu-de",
        "sample_app_git_url": "https://github.com/IBM/gen-ai-rag-watsonx-sample-application"
    }
}
```


## 4. Run ./deploy-many.sh

- Ensure you are login into the account containing the Cloud project with the stack using ibmcloud login --sso
- Execute ./deploy-many.sh with project name, stack name and optional configuration name pattern. The selected non-stack configruations will be processed by their name in alphabetical order. Using configuration name pattern (regex can be used - make sure to enclose it in quotes) you can chose which configurations are deployed

Example 1 - update stack inputs for stack configuration `RAG` and process all non-stack configurations in the project:
```bash
./deploy-many.sh my-test-project RAG
```

Example 2 - update stack inputs and process some configurations in the project:
```bash
./deploy-many.sh my-test-project RAG 'RAG-1|RAG-4|RAG-5'
```

Example 2 - simulate updating stack inputs and validating some configurations in the project in dry-run mode (no changes or actual validation or deployments is done):
```bash
DRY_RUN=true ./deploy-many.sh my-test-project RAG 'RAG-1|RAG-4|RAG-5'
```

Tips: If deployment fail in one of the DA, you may need to remove the configuration name of the deployment that already passes from the pattern before re-running the script.

Tips: to accelerate iteration you may deploy only a subset of the configurations: the bare minimum are key management, security manager, watson saas, alm and rag configuration da. Base account, observability and SCC are not on the critical path to get the app running.
