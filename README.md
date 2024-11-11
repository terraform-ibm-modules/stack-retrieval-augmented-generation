# Retrieval augmented generation (RAG) for watsonx on IBM Cloud

The following [deployable architecture](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da#what-is-da) automates the deployment of a sample gen AI Pattern on IBM Cloud, including all underlying IBM Cloud and WatsonX infrastructure. This architecture implements the best practices for watsonx gen AI Pattern deployment on IBM Cloud, as described in the [reference architecture](https://cloud.ibm.com/docs/pattern-genai-rag?topic=pattern-genai-rag-genai-pattern).

This deployable architecture provides a comprehensive foundation for trust, observability, security, and regulatory compliance. The architecture configures an IBM Cloud account to align with compliance settings. It also deploys key management and secrets management services and the infrastructure to support continuous integration (CI), continuous delivery (CD), and continuous compliance (CC) pipelines for secure management of the application lifecycle. It also deploys the WatsonX services suite and IBM Cloud Elasticsearch to faciliate a RAG pattern. These pipelines facilitate the deployment of the application, check for vulnerabilities and auditability, and help ensure a secure and trustworthy deployment of generative AI applications on IBM Cloud.

## Variations

Two variations are available for this deployable architecture:
1. Basic variation:
   - Code Engine Project: Provisions a Code Engine project, providing a fully managed platform for containerized applications.
   - Application Deployment: Deploys the application on the provisioned Code Engine project.
   - Elasticsearch Enterprise: Provisions an Elasticsearch [enterprise](https://cloud.ibm.com/docs/databases-for-elasticsearch?topic=databases-for-elasticsearch-elastic-offerings) instance for search and analytics capabilities.

2. Standard variation:
   - IBM Cloud OpenShift Cluster: Provisions an [IBM Cloud OpenShift cluster](https://cloud.ibm.com/docs/openshift?topic=openshift-overview)
   - VPC Network Infrastructure: Sets up the underlying VPC network infrastructure to support the OpenShift cluster.
   - Application Deployment: Deploys the application on the provisioned OpenShift cluster.
   - ElasticSearch Platinum Plan: Leverages the platinum plan of ElasticSearch, which includes the [ELSER](https://cloud.ibm.com/docs/databases-for-elasticsearch?topic=databases-for-elasticsearch-elser-embeddings-elasticsearch) model for advanced vector generation capabilities.



## Objective and benefits

This deployable architecture is designed to showcase a fully automated deployment of a retrieval augmented generation application through IBM Cloud Projects. It provides a flexible and customizable foundation for your own watsonx applications on IBM Cloud. This architecture deploys the following [sample application](https://github.com/IBM/gen-ai-rag-watsonx-sample-application) by default.

By using this architecture, you can accelerate your deployment and tailor it to meet your business needs and enterprise goals.

This architecture can help you achieve the following goals:

- Establish trust: The architecture configures the IBM Cloud account to align with the compliance settings that are defined in the [IBM Cloud for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-about) framework, and the [AI Security Guardrails 2.0](https://cloud.ibm.com/docs/security-compliance?topic=security-compliance-ai-security-change-log) profile.
- Ensure observability: The architecture provides observability by deploying services such as IBM Log Analysis, IBM Monitoring, IBM Activity Tracker, and log retention through IBM Cloud Object Storage buckets.
- Implement security: The architecture deploys instances of IBM Key Protect and IBM Secrets Manager.
- Achieve regulatory compliance: The architecture implements CI, CD, and CC pipelines along with IBM Security Compliance Center (SCC) for secure application lifecycle management.

## Before you begin

Before you deploy the deployable architecture, make sure that you complete the following actions:

> [!IMPORTANT]
> You must use an API key that is associated with a user. You can't use service ID keys or trusted profiles.

- Create an API key in the target account with the required permissions. The target account is the account that hosts the resources that are deployed by this architecture. For more information, see [Managing user API keys](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui).
    - Copy the value of the API key. You need it in the following steps.
    - In test or evaluation environments, you can grant the Administrator role on the following services
        - IAM Identity service. In addition to the Administrator role, when deploying the Standard variation of the Deployable Architecture, explicitly assign the `User API key creator` role, as it is mandatory for a successful OpenShift cluster deployment.
        - All Identity and Access enabled services.
        - All Account Management services.

        To scope access to be more restrictive for a production environment, refer to the minimum permission level in the [permission tab](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52-global#permissions) of this deployable architecture.
- Generating and exporting a signing key. This step is optional for deploying the application, but it is required for the CI pipeline to complete successfully. Without this step, the CI pipeline will report a failure due to the missing signing step. If you want to generate and export a signing key, follow these steps:
    - Create or obtain a signing key by running the command `gpg --gen-key` without a passphrase (if not expired, you can use a previously generated key).
    - Export the signing key by running the command `gpg --export-secret-key <email address> | base64`. For more information about storing the key, see [Generating a GPG key](https://cloud.ibm.com/docs/devsecops?topic=devsecops-devsecops-image-signing#cd-devsecops-gpg-export).
    - Copy the value of the key and keep note of the key for later.


## Add the architecture to a project

1.  Go to the **Retrieval Augmented Generation (RAG) Pattern** [details page](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/Retrieval_Augmented_Generation_Pattern-5fdd0045-30fc-4013-a8bc-6db9d5447a52-global) in the IBM Cloud catalog community registry.
1.  Select the latest product version in the Architecture section.
1.  Select the variation **Basic** or **Standard**. Refers to the Variations section above for further details on the two variations.
2.  Click **Add to project**
3.  Select **Create new** and enter the following details:
    1.  Add a name and description.
    2.  Select a region and resource group for the project. For example, for evaluation purposes, you can select the region that is closest to you and the default resource group.

        For more information about the enterprise account structures, see the [Central administration account](/docs/enterprise-account-architecture?topic=enterprise-account-architecture-admin-hub-account) white paper.
    3.  Enter a configuration name. For example, "RAG", "dev" or "prod". The name can help you later to match your deployment target.
4.  Click **Create**

## Configure your stack

You can now create your configuration by setting variables.

1.  From the **Security** panel, select the authentication method that you want to use to deploy your architecture.

    Add the API key from the prerequisites in [Before you begin](#before-you-begin).
1.  In the **Security** > **Authentication** tab in the **Configure** section, select the API key.
1.  Enter values for required fields from the **Required** tab.

    1.  Enter a prefix. This prefix is added to the beginning of the name of most resources that are created by the deployable architecture. The prefix helps to make sure that the resource names are unique, and it avoids clashes with other resources in the same account.
1.  Review values for optional fields from the **Optional** tab:

    1.  Specify the `signing_key` variable from the prerequisites in [Before you begin](#before-you-begin).
    1.  Review the other input variables.
1.  Click **Save**. After the input values are validated, the button changes to **View stack configurations**.

## Deploy the architecture

You can deploy a stacked deployable architecture through the IBM Cloud console in two ways:

- By using **Auto-deploy**: The deployment method can be useful for demonstration and nonproduction environments. With auto-deploy, all the stack member configurations are validated and then approved and deployed.

    You can check the **Auto-deploy** setting for your project by clicking **Manage** > **Settings**. By turning on Auto-deploy, you enable the setting for all configurations in the project.
- Individually by deploying each member configuration. The manual method is appropriate for projects that hold production environments. You can review the changes in each member configuration before the automation is run.

> [!TIP]
> After you approve the configuration, you might receive the error message "Unable to validate your configuration". To resolve the issue, refresh your browser.
>
> You might see "New version available" notifications in the **Needs Attention** column in your project configuration. You can ignore these messages because they do not prevent you from deploying the stack.

### Deploying the architecture with Auto-deploy

1.  Click the **Options** icon ![Options icon](/images/action-menu-icon.svg "Options") next to **View stack configurations** and click **Validate**.

    If the **Auto-deploy** setting is off in your project, only member configurations that are ready are validated.

### Deploying each member configuration

1.  In your project, click the **Configurations** tab.

    If the first member configuration of the stack (`Account Infrastructure Base`) is not marked as **Ready to validate**, refresh the page in your browser.
1.  Click **Validate** in **Draft status** in the `Account Infrastructure Base` row.
1.  Approve the configuration and click **Deploy** after validation successfully completes.
1.  After you deploy the initial member configuration, you can validate and deploy the remaining member configuration at the same time. Repeat these deployment steps for each member configuration in the architecture.

The Retrieval Augmented Generation Pattern deployable architecture is now deployed in the target account.

## Monitor the build and application deployment

### Monitoring the CI pipeline

After the architecture is deployed, the sample application starts in the newly provisioned DevOps service.

To monitor the build and deployment of the application, follow these steps:

1.  Access the DevOps Toolchains view by navigating to [DevOps > Toolchains](https://cloud.ibm.com/devops/toolchains) in the target account.
1.  Select the resource group and region where the infrastructure was deployed. The resource group name is based on the prefix and `resource_group_name` inputs of the deployable architecture.
1.  Select the **RAG Sample App-CI-Toolchain**.
2.  In the toolchain view, select **ci-pipeline** in delivery pipeline.
3.  Look for the status of the CI pipeline execution in the **rag-webhook-trigger** section.

### Verifying the sample application

- Code Engine deployment (Basic): After the CI pipeline completes, you can access the application in the created [Code Engine project](https://cloud.ibm.com/codeengine/projects).
- OpenShift deployment (Standard):
    1.  In your project, click the **Configurations** tab.
    2.  Click the `Workload - Sample RAG App Configuration` row.
    3.  In the `Outputs` tab, the URL to the deployed application is listed under the `sample_app_public_url` output.


## Troubleshooting

### Why does my IBM Cloud Secrets Manager deployment fail?

To minimize costs, the automation deploys a Trial pricing plan of Secrets Manager. You can create only one Trial instance of Secrets Manager. You can deploy a Standard plan instance of Secrets Manager from the **Optional settings** of the stack.

To fix it, delete the trial instance. After deletion, also delete the service from the reclamation state.

In IBM Cloud, when you delete a resource, it doesn't immediately disappear. Instead, it enters a reclamation state, where it remains for a short time (usually 7 days) before being permanently deleted. During the reclamation state, you can recover the resource, if needed.

Run the following IBM Cloud CLI commands to delete the service from the reclamation state.

The first command lists all the resources in the reclamation state.

```sh
# List all the resources in reclamation state with its reclamation ID
ibmcloud resource reclamations
```

Find the reclamation ID of the Secrets Manager service. Use that ID in the following command.

```sh
ibmcloud resource reclamation-delete <reclamation-id>
```

## Customization options

Many customizations are possible with this architecture. These are some common options.

### Editing member configurations

Each member configuration includes a large number of input parameters. You can edit the configuration to change the default values.

For example, by editing the member configuration, you can accomplish these things:

- Fine-tune account settings
- Deploy more Watson components, such as watsonx.governance
- Deploy to an existing resource group
- Reuse existing Key Protect keys
- Reuse existing IBM Cloud service instances (Secrets Manager, key Protect, Event Notifications, Watsonx services)
- Adjust the parameters of your provisioned Code Engine project or OpenShift cluster to meet specific requirements.

To edit the member configuration, select **Edit** from the Options icon ![Options icon](/images/action-menu-icon.svg "Options") in the member configuration row.

### Removing configurations from the stack

You can remove a member configuration from the stack that other configurations don't depend on.

You can remove the following configurations in this architecture:

- Security and Control Center
- Sample RAG App Configuration

To remove a member configuration, select **Remove from Stack** from the Options icon ![Options icon](/images/action-menu-icon.svg "Options") in the member configuration row.

### Managing input and output variables

You can add or remove input and output variables at the stack level by following these steps:

1.  In the IBM Cloud console, click the **Navigation menu** icon ![Navigation menu icon](/images/icon_hamburger.svg "Menu") > **Projects**.
1.  Click the project with the stacked deployable architecture that you want to update.
1.  Click the **Configurations** tab.
1.  Select a member configuration.
1.  From the deployed details window, you can promote any of the configuration inputs or outputs.

### Selective provisioning of observability resources

You can selectively provision observability resources such as Activity Tracker routes and targets, and Cloud Monitoring instances by following these steps:

1.  In the IBM Cloud console, click the **Navigation menu** icon ![Navigation menu icon](/images/icon_hamburger.svg "Menu") > **Projects**.
2.  Click the project with the stacked deployable architecture that you want to update.
3.  Click the **Configurations** tab.
4.  **Navigate to the Configurations**: Access the "Essential Security - Logging Monitoring Activity Tracker" configuration by clicking on it.
5.  **Edit Member Configuration**: On the top right side click on 3 dots, then select Edit option to access the member configuration page.
6.  **Locate Optional Variables**: Under the Optional tab, you’ll find the specific variable settings.
7.  From the deployed details window, you can enable or disable the provisioning of specific observability resources. For example:
    - **IBM Cloud Logs instance** (`cloud_logs_provision`): Set this to provision or skip provisioning an IBM Cloud Logs instance.
     - **IBM Cloud Monitoring instance** (`cloud_monitoring_provision`): Set this to provision or skip provisioning an IBM cloud monitoring instance.
    - **Event routing from Activity Tracker to Object Storage** (`enable_at_event_routing_to_cos_bucket`): Set this to enable or disable event routing from Activity Tracker to the Object Storage bucket.
    - **Event routing from Activity Tracker to Cloud Logs** (`enable_at_event_routing_to_cloud_logs`): Set this to enable or disable event routing from Activity Tracker to Cloud Logs.
8.  After making the necessary changes, click Save, validate the settings, and deploy to apply the updated configuration.



### Sharing modified stacks through a private IBM Cloud catalog

After you modify your deployable architecture in projects, you can share it with others through a private IBM Cloud catalog. To share your deployable architecture, follow the steps in [Sharing your deployable architecture to your enterprise](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-share-custom).

### Customizing your application

You can use the code of this sample automation as a guide to customize the sample app to meet your requirements. The code is available at [https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da](https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da).

To use your own app, remove the `Workload - Sample RAG App Configuration` member configuration from the stack. This member configuration is specific to the default sample app.

## Undeploying the stack and infrastructure


1.  Clean up the configuration

    This step is optional if you plan to destroy all Watson resources. The artifacts that are created by the application are deleted as part of undeploying the Watson resources.

    Follow the steps outlined in the [cleanup.md](https://github.com/IBM/gen-ai-rag-watsonx-sample-application/blob/main/artifacts/artifacts-cleanup.md) file to remove the configuration for the sample app.

1.  Delete resources created by the CI toolchain

    The following resources, which are created by the toolchain, are not destroyed as part of undeploying the stack in Project.

    - Code Engine Project
        - Delete the code engine project created for the sample application.
    - Container Registry Namespace
        - Delete the container registry namespace created by the CI tookchain.

1.  Delete the project.

    To undeploy the infrastructure created by the deployable architecture, follow the steps in [Deleting a project](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-delete-project) in the IBM Cloud docs.
