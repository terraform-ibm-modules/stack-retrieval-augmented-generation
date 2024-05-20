# Retrieval augmented generation for watsonx on IBM Cloud

The following [deployable architecture](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da#what-is-da) automates the deployment of a sample gen AI Pattern on IBM Cloud, including all underlying IBM Cloud infrastructure. This architecture implements the best practices for watsonx gen AI Pattern deployment on IBM Cloud, as described in the [reference architecture](https://cloud.ibm.com/docs/pattern-genai-rag?topic=pattern-genai-rag-genai-pattern).

This deployable architecture provides a comprehensive foundation for trust, observability, security, and regulatory compliance. The architecture configures an IBM Cloud account to align with compliance settings. It also deploys key management and secrets management services and the infrastructure to support continuous integration (CI), continuous delivery (CD), and continuous compliance (CC) pipelines for secure management of the application lifecycle. These pipelines facilitate the deployment of the application, check for vulnerabilities and auditability, and help ensure a secure and trustworthy deployment of generative AI applications on IBM Cloud.

# Objective and benefits

This deployable architecture is designed to showcase a fully automated deployment of a retrieval augmented generation application through IBM Cloud Projects. It provides a flexible and customizable foundation for your own watsonx applications on IBM Cloud. This architecture deploys the following [sample application](https://github.com/IBM/gen-ai-rag-watsonx-sample-application) by default.

By using this architecture, you can accelerate your deployment and tailor it to meet your business needs and enterprise goals.

This architecture can help you achieve the following goals:

- Establish trust: The architecture configures the IBM Cloud account to align with the compliance settings that are defined in the [IBM Cloud for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-about) framework.
- Ensure observability: The architecture provides observability by deploying services such as IBM Log Analysis, IBM Monitoring, IBM Activity Tracker, and log retention through IBM Cloud Object Storage buckets.
- Implement security: The architecture deploys instances of IBM Key Protect and IBM Secrets Manager.
- Achieve regulatory compliance: The architecture implements CI, CD, and CC pipelines along with IBM Security Compliance Center (SCC) for secure application lifecycle management.

# Deploying

To deploy this architecture, follow these steps.

## Before you begin

Before you deploy the deployable architecture, make sure that you complete the following actions:

- Create an API key in the target account with the required permissions. The target account is the account that hosts the resources that are deployed by this architecture. For more information, see [Managing user API keys](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui).

    - Copy the value of the API key. You need it in the following steps.
    - In test or evaluation environments, you can grant the Administrator role on the following services
        - IAM Identity service
        - All Identity and Access enabled services
        - All Account Management services.

        To scope access to be more restrictive for a production environment, refer to the minimum permission level in the [permission tab](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52-global#permissions) of this deployable architecture.
- Create or have access to a signing key, which is the Base64 key that is obtained from the `gpg --gen-key` command without a passphrase (if not expired generated previously). Export the signing key by running the command `gpg --export-secret-key <email address> | base64` command. For more information about storing the key, see [Generating a GPG key](https://cloud.ibm.com/docs/devsecops?topic=devsecops-devsecops-image-signing#cd-devsecops-gpg-export). Copy the value of the key.

    :information_source: **Tip:** The signing key is not required to deploy all the Cloud resources that are created by this deployable architecture. However, the key is necessary to get the automation to build and deploy the sample application.
- [Install or update ](https://cloud.ibm.com/docs/cli?topic=cli-getting-started) the IBM Cloud CLI.
- Optional: Install the Project CLI plug-in by running the `ibmcloud plugin install project` command. For more information, see the [Project CLI reference](https://cloud.ibm.com/docs/cli?topic=cli-projects-cli).
- Read the [Deployment considerations](#deployment-considerations).

## Add the architecture to a project

1.  Locate the [tile](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52-global) for the deployable architecture in the IBM Cloud catalog.
1.  Click "Add to project".

    ![Add the deployable architecture to a project](./images/min/1-catalog.png "Screenshot of Add to project")
1.  Select **Create new** and enter the following details:
    1.  Add a name and description.
    1.  Select a region and resource group for the project. For example, for evaluation purposes, you can select the region that is closest to you and the default resource group.

        For more information about the recommended production topology, see the [Central administration account](https://cloud.ibm.com/docs/enterprise-account-architecture?topic=enterprise-account-architecture-admin-hub-account) white paper.
    1.  Enter a configuration name. For example, "RAG", "dev" or "prod". It can be a help later on to match your deployment target.

        ![Define project details](./images/min/2-project.png "Screenshot of define project details window")
1.  Click **Add** (or **Create** for the initial project in the account).

## Configure your stack

You can now create your configuration by setting variables.

1.  From the **Security** tab in the **Configure** section, select the API key from the prerequisites in [Before you begin](#before-you-begin).

    ![Define and configure project details](./images/min/3-inputs.png "Screenshot of edit project configuration")
1.  Select the **Required** tab and enter a prefix. This prefix is added to the beginning of the name of most resources that are created by the deployable architecture. The prefix helps to make sure that the resource names are unique, and it avoids clashes with other resources in the same account.
1.  Select the **Optional** tab and specify the `signing_key` variable from the prerequisites in [Before you begin](#before-you-begin).
1.  Optional: Review and update the other input variables, such as the region and resource group name.
1.  Click **Save** at the top of the screen.

## Deploy the architecture

You can deploy the architecture either through the IBM Cloud console or by running a script.

- [Configuring an architecture by using the console](#deploy-by-using-the-console)
- [Configuring an architecture by running the script](#deploy-by-running-the-script)

### Deploy by using the console

1.  Navigate to the project deployment view by clicking the project name in the breadcrumb.

    ![Projects breadcrumb menu](./images/min/4-bread.png "Screenshot of project breadcrumb")
1.  In the Configurations tab, click **Validate** under the **Draft status** column for the first member configuration.

    ![Validate button](./images/min/5b-validate.png)
1.  Approve the configuration and click **Deploy** after validation completes.
1.  After you deploy the initial member configuration, you can validate and deploy the remaining member configuration at the same time. Repeat these steps for each member configuration in the architecture.

### Deploy by running the script

1.  Clone the repository at https://github.com/terraform-ibm-modules/stack-retrieval-augmented-generation/tree/main
1.  Run the IBM Cloud CLI command `ibmcloud login`. Make sure that you log in to the account that owns the project with the stack.
1.  Run the `./deploy-many.sh` script with the project name, stack name, and optional configuration name pattern.

    :information_source: **Tip:** If deployment fails for one of the member configurations, rerun the script. The script skips any installed configurations and continues from where it failed.

The following example deploys all the configurations in the `my-test-project` project and `dev` stack:

```sh
./deploy-many.sh my-test-project dev
```

## Verifying the sample application

After the architecture is deployed, the sample application starts in the newly provisioned DevOps service. You can access the application in the created [Code Engine project](https://cloud.ibm.com/codeengine/projects).

## Enabling Watson Assistant

After the application is built and is running in Code Engine, enable Watson Assistant in the app. To complete the installation, follow the steps that are outlined in the [Configuration steps for watsonx Assistant artifacts](https://github.com/IBM/gen-ai-rag-watsonx-sample-application/blob/main/artifacts/artifacts-README.md) readme file in the gen-ai-rag-watsonx-sample-application GitHub project.

### Monitoring the build and deployment

To monitor the build and deployment of the application, follow these steps:
1.  **Access the DevOps Toolchains View**: Navigate to the [DevOps / Toolchains view](https://cloud.ibm.com/devops/toolchains) in the target account.
2.  **Select the Resource Group and Region**: Choose the resource group and region where the infrastructure was deployed. The resource group name is based on the prefix and resource_group_name inputs of the deployable architecture.
3.  **Select the Toolchain**: Select "RAG Sample App-CI-Toolchain"
    ![Toolchain](./images/min/8-toolchain.png)
4.  **Access the Delivery Pipeline**: In the toolchain view, select **ci-pipeline** in "Delivery pipelines".
    ![Toolchain](./images/min/9-pipeline.png)
5.  **View the CI Pipeline Status**: The status of the CI pipeline execution is in the "rag-webhook-trigger" section.

## Deployment considerations

The following aspects might affect your deployment.

### API key requirements

The deployable architecture can be deployed only with an API key that is associated with a user. You can't use service ID keys or trusted profiles.

### Unable to validate your configuration message

After you approve the configuration, you might receive the error message "Unable to validate your configuration". To resolve the issue, refresh your browser.

### Limitations of the script

The `deploy-many.sh` script is designed to deploy the default configurations. Don't use the script if you modify the configuration in ways other than specifying inputs or if you deploy the stack to an existing project. Use the projects console instead.

### Notification of new configuration versions

You might see "New version available" notifications in the **Needs Attention** column in your project configuration. You can ignore these messages because they do not prevent you from deploying the stack.

### Limitations with the trial Secrets Manager pricing plan

To minimize costs, the automation deploys a Trial pricing plan of Secrets Manager by default, which has limitations. To avoid these limitations, you can deploy a standard (paid) instance of Secrets Manager under the **Optional settings** of the stack.

Some limitations of the Trial version of Secrets Manager:
- Account limitation: You can have only one Trial instance of Secrets Manager in an account. An error is displayed in the Secrets Manager deployment step if a Trial instance exists in the same account.
- Redeployment failure because of reclamation: If the default Trial instance of Secrets Manager is undeployed and then redeployed in the same account, the deployment of the **2b - Security Service - Secrets Manager** deployment member configuration fails. You must delete the existing Trial instance and its reclamation claim by running the following commands:

    ```sh
    ibmcloud resource reclamations # lists all the resources in reclamation state with its reclamation ID
    ibmcloud resource reclamation-delete <reclamation-id>
    ```

    :information_source: **Tip:** Reclamation refers to the period after a resource is deleted but before it is destroyed. When a service instance is deleted, the data is not deleted immediately. Instead, it is scheduled for reclamation (by default, this schedule is set to 7 days). It is possible to restore a deleted resource that is not yet reclaimed.

# Customization options

Many customizations are possible with this architecture. This section explores some common scenarios.

## Editing individual configurations

Each member configuration includes many input variables. You can edit those parameters by selecting **Edit** on the right side of the configuration.

![Edit config](./images/min/11-edit-config.png)

Editing the member configuration supports changes such as the following changes:

- Fine-tune account settings
- Deploy more Watson components, such as watsonx.governance
- Deploy to a resource group
- Reuse existing Key Protect keys
- Tune the parameters of the provisioned Code Engine project

## Removing configurations from the stack

You can remove any configuration from the stack, as long as other configurations don't depend on it. Select the **Remove from Stack** option at the right side of the configuration that you want to remove.

You can remove the following configurations in this architecture:

- Observability
- Security and Control Center

![Edit config](./images/min/12-remove-config.png)

## Managing input and output variables

You can add or remove input and output variables at the stack level by following these steps:
1.  Select the stack configuration

    ![Stack definition](./images/min/13-define-stack.png)
1.  In the "Define stack variables" screen, select the inputs that you want users to configure and outputs that you want displayed.

    ![Stack definition](./images/min/14-stack-def.png)

## Sharing modified stacks through a private IBM Cloud catalog

After you modify your stack in projects, you can share it with others through a private IBM Cloud catalog. To do so, follow these steps in [Sharing your deployable architecture to your enterprise](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-share-custom).

## Customizing your application

To customize the configuration to your requirements, you might want to customize the sample app. You can use the code of this sample automation as a guide. The code is available at [https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da](https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da).

To use your own app, first remove the **Sample RAG app configuration** member configuration in the stack. This configuration is specific to the default sample app.

## Undeploying the stack and infrastructure

Delete the stack and all associated infrastructure resources.

1.  Clean up the configuration

    :information_source: **Tip:** This step is optional if you plan to destroy all Watson resources. The artifacts that are created by the application are deleted as part of undeploying the Watson resources.

    1.  Follow the steps outlined in the [cleanup.md](https://github.com/IBM/gen-ai-rag-watsonx-sample-application/blob/main/artifacts/artifacts-cleanup.md) file to remove the configuration for the sample app.
1.  Delete the resources created by the CI toolchain. These resources are not destroyed when you undeploy the stack in projects:
    - **Code Engine Project**: Delete the code engine project created for the sample application.
    - **Container Registry Namespace**: Delete the Container Registry namespace created by the CI toolchain.
1.  Undeploy each configuration in the project in the Cloud console:
    1.  Undeploy the **6 - Sample RAG app configuration** member. Wait for the undeploy to complete.
    1.  Undeploy the next member configuration. Wait for the undeploy to complete.
    1.  Continue to undeploy the configurations, but wait for each undeploy to complete before you undeploy the next.

        Stop after the **2a - Security Service - Key Management** member configuration.
1. Delete the reclamation claims:

    Before you undeploy the top member configuration (**1 - Account Infrastructure Base**), delete the reclamation claims for the resources that you deleted in the previous step. Any reclamation that is still active prevents you from deleting the resource group that is managed by the top member configuration. Through reclamation, you can restore deleted resources for up to one week from when you delete them.

    For more information, see [Using resource reclamations](https://cloud.ibm.com/docs/account?topic=account-resource-reclamation&interface=cli).

    1.  Log in to the target IBM Cloud account with the IBM Cloud CLI.
    1.  Run the following command to view the list of reclamations and to get the reclamation ID.

        ```sh
        ibmcloud resource reclamations
        ```

    1.  Run the following command for each reclamation ID that you want to delete:

        ```sh
        ibmcloud resource reclamation-delete <reclamation-id>`
        ```

    1.  Run the command to list the reclamations again to make sure that all are deleted:

        ```sh
        ibmcloud resource reclamations
        ```

1.  Undeploy the last **1 - Account Infrastructure Base** member configuration: in the project.
1.  Delete your project. After all configurations are undeployed, you can delete the project.
