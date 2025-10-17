########################################################################################################################
# Resource Group
########################################################################################################################

output "resource_group_id" {
  description = "The resource group ID to provision the Watson Discovery instance."
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "The resource group name to provision the Watson Discovery instance."
  value       = module.resource_group.resource_group_name
}

########################################################################################################################
# watsonx.ai
########################################################################################################################

output "watsonx_ai" {
  description = "Project configuration and instance details generate from the watsonx.ai module."
  value = {

    # watsonx.ai Project
    "watsonx_ai_project_id"          = module.watsonx_ai.watsonx_ai_project_id
    "watsonx_ai_project_url"         = module.watsonx_ai.watsonx_ai_project_url
    "watsonx_ai_project_bucket_name" = module.watsonx_ai.watsonx_ai_project_bucket_name

    # watsonx.ai Runtime
    "watsonx_ai_runtime_crn"           = module.watsonx_ai.watsonx_ai_runtime_crn
    "watsonx_ai_runtime_guid"          = module.watsonx_ai.watsonx_ai_runtime_guid
    "watsonx_ai_runtime_name"          = module.watsonx_ai.watsonx_ai_runtime_name
    "watsonx_ai_runtime_plan_id"       = module.watsonx_ai.watsonx_ai_runtime_plan_id
    "watsonx_ai_runtime_dashboard_url" = module.watsonx_ai.watsonx_ai_runtime_dashboard_url

    # watsonx.ai Studio
    "watsonx_ai_studio_crn"           = module.watsonx_ai.watsonx_ai_studio_crn
    "watsonx_ai_studio_guid"          = module.watsonx_ai.watsonx_ai_studio_guid
    "watsonx_ai_studio_name"          = module.watsonx_ai.watsonx_ai_studio_name
    "watsonx_ai_studio_plan_id"       = module.watsonx_ai.watsonx_ai_studio_plan_id
    "watsonx_ai_studio_dashboard_url" = module.watsonx_ai.watsonx_ai_studio_dashboard_url

    # COS KMS 
    "cos_kms_key_crn" = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
  }
}

########################################################################################################################
# watson Discovery
########################################################################################################################

output "watson_discovery" {
  description = "Connection and configuration details for the Watson Discovery instance."
  value = {
    "crn"           = module.watson_discovery.crn
    "account_id"    = module.watson_discovery.account_id
    "guid"          = module.watson_discovery.guid
    "name"          = module.watson_discovery.name
    "plan_id"       = module.watson_discovery.plan_id
    "dashboard_url" = module.watson_discovery.dashboard_url
  }
}

# output "watson_discovery_account_id" {
#   description = "Account ID of the Watson Discovery instance."
#   value       = module.watson_discovery.account_id
# }

# output "watson_discovery_crn" {
#   description = "CRN of the Watson Discovery instance."
#   value       = module.watson_discovery.crn
# }

# output "watson_discovery_guid" {
#   description = "GUID of the Watson Discovery instance."
#   value       = module.watson_discovery.guid
# }

# output "watson_discovery_name" {
#   description = "Name of the Watson Discovery instance."
#   value       = module.watson_discovery.name
# }

# output "watson_discovery_plan_id" {
#   description = "Plan ID of the Watson Discovery instance."
#   value       = module.watson_discovery.plan_id
# }

# output "watson_discovery_dashboard_url" {
#   description = "Dashboard URL of the Watson Discovery instance."
#   value       = module.watson_discovery.dashboard_url
# }

########################################################################################################################
# watsonx Assistant
########################################################################################################################

output "watsonx_assistant" {
  description = "Connection and configuration details for the watsonx Assistant instance."
  value = {
    "crn"           = module.watsonx_assistant.crn
    "account_id"    = module.watsonx_assistant.account_id
    "guid"          = module.watsonx_assistant.guid
    "name"          = module.watsonx_assistant.name
    "plan_id"       = module.watsonx_assistant.plan_id
    "dashboard_url" = module.watsonx_assistant.dashboard_url
  }
}

########################################################################################################################
# ICD - ElasticSearch
########################################################################################################################

output "icd_elastic_search" {
  description = "ICD Elastic search output."
  value = {
    "crn"                = module.icd_elasticsearch.crn
    "id"                 = module.icd_elasticsearch.id
    "version"            = module.icd_elasticsearch.version
    # "adminuser"          = module.icd_elasticsearch.adminuser
    "hostname"           = module.icd_elasticsearch.hostname
    "port"               = module.icd_elasticsearch.port
    # "certificate_base64" = module.icd_elasticsearch.certificate_base64
    "service_credentials_json" = module.icd_elasticsearch.service_credentials_json
  }
}

########################################################################################################################
# Code Engine
########################################################################################################################