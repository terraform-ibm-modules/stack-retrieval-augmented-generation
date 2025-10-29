##############################################################################################################
# Locals Block
##############################################################################################################

locals {

  prefix            = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  service_endpoints = "public-and-private"

  # KMS
  key_ring_name = "${local.prefix}keyring"
  key_name      = "${local.prefix}key"

  # ICD Elastic Search
  es_credentials = {
    "elasticsearch_admin" : "Administrator",
    "elasticsearch_operator" : "Operator",
    "elasticsearch_viewer" : "Viewer",
    "elasticsearch_editor" : "Editor",
  }
  es_index_name = "${local.prefix}es-index"

}

##############################################################################################################
# Resource Group
##############################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}

##############################################################################
# COS
##############################################################################

module "cos" {
  source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version           = "10.5.2"
  resource_group_id = module.resource_group.resource_group_id
  cos_instance_name = "${local.prefix}cos"
  cos_plan          = "standard"
  cos_tags          = var.resource_tags
}

##############################################################################
# Key Protect
##############################################################################

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "5.4.5"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${local.prefix}kp"
  resource_tags             = var.resource_tags
  keys = [
    {
      key_ring_name = local.key_ring_name
      keys = [
        {
          key_name     = local.key_name
          force_delete = true
        }
      ]
    }
  ]
}

##############################################################################################################
# watsonx.ai
##############################################################################################################

data "ibm_iam_auth_token" "restapi" {}

module "watsonx_ai" {
  source                           = "terraform-ibm-modules/watsonx-ai/ibm"
  version                          = "2.9.1"
  region                           = var.region
  resource_group_id                = module.resource_group.resource_group_id
  resource_tags                    = var.resource_tags
  project_name                     = "${local.prefix}project-rag"
  watsonx_ai_studio_instance_name  = "${local.prefix}wx-studio"
  watsonx_ai_studio_plan           = "professional-v1"
  watsonx_ai_runtime_instance_name = "${local.prefix}wx-runtime"
  watsonx_ai_runtime_plan          = "v2-professional"
  enable_cos_kms_encryption        = true
  cos_instance_crn                 = module.cos.cos_instance_crn
  cos_kms_key_crn                  = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
}

##############################################################################################################
# Watson Discovery
##############################################################################################################

module "watson_discovery" {
  source                = "terraform-ibm-modules/watsonx-discovery/ibm"
  version               = "1.11.2"
  region                = var.region
  resource_group_id     = module.resource_group.resource_group_id
  resource_tags         = var.resource_tags
  plan                  = "plus"
  watson_discovery_name = "${local.prefix}discovery"
  service_endpoints     = local.service_endpoints
}

##############################################################################################################
# watsonx Assistant
##############################################################################################################

module "watsonx_assistant" {
  source                 = "terraform-ibm-modules/watsonx-assistant/ibm"
  version                = "1.5.2"
  region                 = var.region
  resource_group_id      = module.resource_group.resource_group_id
  resource_tags          = var.resource_tags
  plan                   = "enterprise"
  watsonx_assistant_name = "${local.prefix}assistant"
  service_endpoints      = local.service_endpoints
}

##############################################################################################################
# Elastic search
##############################################################################################################

module "icd_elasticsearch" {
  source                   = "terraform-ibm-modules/icd-elasticsearch/ibm"
  version                  = "2.4.5"
  resource_group_id        = module.resource_group.resource_group_id
  name                     = "${local.prefix}data-store"
  region                   = var.region
  plan                     = "enterprise"
  elasticsearch_version    = "8.12"
  tags                     = var.resource_tags
  service_endpoints        = "private"
  member_host_flavor       = "multitenant"
  deletion_protection      = false
  service_credential_names = local.es_credentials
}

// Create Elastic search index
resource "elasticsearch_index" "es_create_index" {
  provider           = elasticsearch.ibm_es
  depends_on         = [module.icd_elasticsearch]
  name               = local.es_index_name
  number_of_shards   = 1
  number_of_replicas = 1
  force_destroy      = true
}

##############################################################################################################
# Container Registry
##############################################################################################################

module "icr_namespace" {
  source            = "terraform-ibm-modules/container-registry/ibm"
  version           = "2.2.1"
  resource_group_id = module.resource_group.resource_group_id
  namespace_name    = "${local.prefix}namespace"
}

##############################################################################################################
# Code Engine
##############################################################################################################

locals {
  env_vars = [
    {
      type  = "literal"
      name  = "WATSONX_AI_APIKEY"
      value = sensitive(var.ibmcloud_api_key)
    },
    {
      type  = "literal"
      name  = "WATSONX_PROJECT_ID"
      value = module.watsonx_ai.watsonx_ai_project_id
    },
    {
      type  = "literal"
      name  = "ENABLE_WXASST"
      value = "true"
    },
    {
      type  = "literal"
      name  = "WXASST_REGION"
      value = var.region
    },
    {
      type  = "literal"
      name  = "ENABLE_RAG_LLM"
      value = "true"
    }
  ]
  output_image = "private.${var.region}.icr.io/${module.icr_namespace.namespace_name}/ai-agent-for-loan-risk"
  url          = "https://github.com/IBM/ai-agent-for-loan-risk"
  strategy     = "dockerfile"
  ce_app_name  = "ai-agent-for-loan-risk"
}

##############################################################################
# Code Engine Project
##############################################################################
module "code_engine_project" {
  source            = "terraform-ibm-modules/code-engine/ibm//modules/project"
  version           = "4.6.4"
  name              = "${local.prefix}project"
  resource_group_id = module.resource_group.resource_group_id
}

##############################################################################
# Code Engine Secret
##############################################################################
module "code_engine_secret" {
  source     = "terraform-ibm-modules/code-engine/ibm//modules/secret"
  version    = "4.6.4"
  name       = "${local.prefix}registry-secret"
  project_id = module.code_engine_project.id
  format     = "registry"
  data = {
    "server"   = "private.${var.region}.icr.io",
    "username" = "${local.prefix}user",
    "password" = sensitive(var.ibmcloud_api_key),
  }
}

##############################################################################
# Code Engine Build
##############################################################################

module "code_engine_build" {
  source                     = "terraform-ibm-modules/code-engine/ibm//modules/build"
  version                    = "4.6.4"
  name                       = "${local.prefix}-ce-build"
  ibmcloud_api_key           = var.ibmcloud_api_key
  project_id                 = module.code_engine_project.id
  existing_resource_group_id = module.resource_group.resource_group_id
  source_url                 = local.url
  strategy_type              = local.strategy
  output_secret              = module.code_engine_secret.name
  output_image               = local.output_image
}

##############################################################################
# Code Engine Application
##############################################################################
module "code_engine_app" {
  depends_on                    = [module.code_engine_build]
  source                        = "terraform-ibm-modules/code-engine/ibm//modules/app"
  version                       = "4.6.4"
  project_id                    = module.code_engine_project.id
  name                          = local.ce_app_name
  image_reference               = module.code_engine_build.output_image
  image_secret                  = module.code_engine_secret.name
  run_env_variables             = local.env_vars
  scale_cpu_limit               = "4"
  scale_memory_limit            = "32G"
  scale_ephemeral_storage_limit = "300M"
  managed_domain_mappings       = "local_private"
}

##############################################################################################################
