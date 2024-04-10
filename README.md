# Retrievel Augmented Generation (RAG) stack

To run the full stack. These steps will be updated as development progresses on the stack and underlaying DAs.

## 1. Deploy the stack in a new project from catalog

Catalog url: https://cloud.ibm.com/catalog/7df1e4ca-d54c-4fd0-82ce-3d13247308cd/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52?bss_account=9f9af00a96104f49b6509aa715f9d6a5

Click the "Add to project" button, and select create in new project.

## 2. Prereqs in target account

- Create an API key in the target account. Keep note of it. Give it admin privilege for now ( will be narrowed down in future version )
- Create a resource group in the target account (this steps is temporary in current alpha version).


## 3. Set the input configuration for the stack

- Clone this repository locally
- Create a file with name ".def.json" with the following content. Ensure region is either us-south or eu-de (watsonx limitation for now)

```json
{
    "inputs": {
        "prefix": "<prefix for resources name>",
        "ibmcloud_api_key": "<API Key of the target account with sufficient permissions>",
        "resource_group_name": "<target resource group - must be existing in account>",
        "region": "<region where resources are deployed>",
        "sample_app_git_url": "https://github.com/IBM/gen-ai-rag-watsonx-sample-application"
    }
}```

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

## 4. Get the configuration ids for each element of the stack

Run `ibmcloud project configs --project-id <project_id>`

Project id is the id of the project created in step 1. The id can be found under the Manage -> Details tab in the project. 

Take note the id of each config.

## 5. Edit your local copy of deploy-many.sh

In deploy-many.sh:
- Set PROJECT_ID to the id of the project
- Add set the CONFIG_IDS to the array of configurations (ensuring ordering)
CONFIG_IDS=("9618c574-4e0d-4e89-ac55-440717c8b378" "545c1a92-fa21-447f-96ed-fbefb7c50b35" "9aca1cae-36e3-4d1a-96fe-a4ddec057c01" "3eab3b42-f8d4-4532-b0d2-05ef2cc9c250" "b3dbe0de-1512-4351-b0f5-bb8ae8be4d4b")
- Set STACK_CONFIG_ID to the id of the config corresponding to the stack


## 6. Run ./deploy-many.sh

- Ensure you are login using ibmcloud login --sso
- Execute ./deploy-many.sh


