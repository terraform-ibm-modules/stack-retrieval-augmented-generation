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
# KMS
########################################################################################################################

output "kms_key_crn" {
  description = "CRN of the KMS Key."
  value       = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
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
# watsonx.governance
########################################################################################################################

output "watsonx_governance" {
  description = "Connection and configuration details for the watsonx.governance instance."
  value = {
    "crn"           = module.watsonx_governance.crn
    "account_id"    = module.watsonx_governance.account_id
    "guid"          = module.watsonx_governance.guid
    "name"          = module.watsonx_governance.name
    "plan_id"       = module.watsonx_governance.plan_id
    "dashboard_url" = module.watsonx_governance.dashboard_url
  }
}

########################################################################################################################
# watsonx.data
########################################################################################################################

output "watsonx_data" {
  description = "Connection and configuration details for the watsonx.data instance."
  value = {
    "crn"           = module.watsonx_data.crn
    "account_id"    = module.watsonx_data.account_id
    "guid"          = module.watsonx_data.guid
    "name"          = module.watsonx_data.name
    "plan_id"       = module.watsonx_data.plan_id
    "dashboard_url" = module.watsonx_data.dashboard_url
  }
}

########################################################################################################################
# watsonx.data
########################################################################################################################

output "watsonx_orchestrate" {
  description = "Connection and configuration details for the watsonx Orchestrate instance."
  value = {
    "crn"           = module.watsonx_orchestrate.crn
    "account_id"    = module.watsonx_orchestrate.account_id
    "guid"          = module.watsonx_orchestrate.guid
    "name"          = module.watsonx_orchestrate.name
    "plan_id"       = module.watsonx_orchestrate.plan_id
    "dashboard_url" = module.watsonx_orchestrate.dashboard_url
  }
}

########################################################################################################################
# ICD - ElasticSearch
########################################################################################################################

output "icd_elastic_search" {
  description = "ICD Elastic search output."
  value = {
    "crn"      = module.icd_elasticsearch.crn
    "id"       = module.icd_elasticsearch.id
    "version"  = module.icd_elasticsearch.version
    "hostname" = module.icd_elasticsearch.hostname
    "port"     = module.icd_elasticsearch.port
  }
}

output "icd_es_service_credentials_json" {
  description = "ICD Elastic search credentials json."
  value       = module.icd_elasticsearch.service_credentials_json
  sensitive   = true
}

########################################################################################################################
# Container Registry
########################################################################################################################
output "icr_namespace_crn" {
  description = "CRN representing the Container Registry namespace"
  value       = module.icr_namespace.namespace_crn
}

########################################################################################################################
# Code Engine
########################################################################################################################

output "code_engine" {
  description = "Code Engine output."
  value = {
    "project_id"   = module.code_engine.project_id
    "app_url"      = module.code_engine_app.endpoint
    "output_image" = local.output_image
  }
}

########################################################################################################################