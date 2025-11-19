##############################################################################################################
# Locals Block
##############################################################################################################

locals {

  prefix            = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  service_endpoints = "public-and-private"

  # KMS
  key_ring_name    = "${local.prefix}keyring"
  key_name         = "${local.prefix}key"
  wx_data_key_name = "${local.prefix}wxd-key"

  # ICD Elastic Search
  es_credentials = {
    "elasticsearch_admin" : "Administrator",
    "elasticsearch_operator" : "Operator",
    "elasticsearch_viewer" : "Viewer",
    "elasticsearch_editor" : "Editor",
  }

  # Watson
  watson_plan = {
    "studio"      = "professional-v1",
    "runtime"     = "v2-professional",
    "discovery"   = "plus",
    "assistant"   = "enterprise",
    "governance"  = "essentials",
    "data"        = "lakehouse-enterprise",
    "orchestrate" = "essentials-agentic-mau"
  }

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
  version                   = "5.5.0"
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
        },
        {
          key_name     = local.wx_data_key_name
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
  source            = "terraform-ibm-modules/watsonx-ai/ibm"
  version           = "2.10.1"
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id
  resource_tags     = var.resource_tags
  project_name      = "${local.prefix}project-cnai"

  watsonx_ai_studio_instance_name = "${local.prefix}wx-studio"
  watsonx_ai_studio_plan          = local.watson_plan["studio"]

  watsonx_ai_runtime_instance_name = "${local.prefix}wx-runtime"
  watsonx_ai_runtime_plan          = local.watson_plan["runtime"]

  enable_cos_kms_encryption = true
  cos_instance_crn          = module.cos.cos_instance_crn
  cos_kms_key_crn           = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
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
  plan                  = local.watson_plan["discovery"]
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
  plan                   = local.watson_plan["assistant"]
  watsonx_assistant_name = "${local.prefix}assistant"
  service_endpoints      = local.service_endpoints
}

##############################################################################################################
# watsonx.governance
##############################################################################################################

module "watsonx_governance" {
  source                  = "terraform-ibm-modules/watsonx-governance/ibm"
  version                 = "1.11.6"
  region                  = var.region
  resource_group_id       = module.resource_group.resource_group_id
  plan                    = local.watson_plan["governance"]
  watsonx_governance_name = "${local.prefix}governance"
  resource_tags           = var.resource_tags
}

##############################################################################################################
# watsonx.data
##############################################################################################################

module "watsonx_data" {
  source                        = "terraform-ibm-modules/watsonx-data/ibm"
  version                       = "1.12.7"
  region                        = var.region
  resource_group_id             = module.resource_group.resource_group_id
  watsonx_data_name             = "${local.prefix}data"
  plan                          = local.watson_plan["data"]
  use_case                      = "workloads"
  resource_tags                 = var.resource_tags
  enable_kms_encryption         = true
  skip_iam_authorization_policy = false
  watsonx_data_kms_key_crn      = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.wx_data_key_name}"].crn
}

##############################################################################################################
# watsonx Orchestrate
##############################################################################################################

module "watsonx_orchestrate" {
  source                   = "terraform-ibm-modules/watsonx-orchestrate/ibm"
  version                  = "1.11.6"
  region                   = var.region
  resource_group_id        = module.resource_group.resource_group_id
  watsonx_orchestrate_name = "${local.prefix}orchestrate"
  plan                     = local.watson_plan["orchestrate"]
  resource_tags            = var.resource_tags
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
  elasticsearch_version    = "8.15"
  tags                     = var.resource_tags
  service_endpoints        = "private"
  member_host_flavor       = "multitenant"
  deletion_protection      = false
  service_credential_names = local.es_credentials
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

module "cr_endpoint" {
  source  = "terraform-ibm-modules/container-registry/ibm//modules/endpoint"
  version = "2.3.5"
  region  = var.region
}

##############################################################################################################
# Code Engine - Project, Secret, Build, Application
##############################################################################################################

locals {
  env_vars = [{
    type      = "secret_key_reference"
    name      = "WATSONX_AI_APIKEY"
    key       = "WATSONX_AI_APIKEY"
    reference = "wx-ai"
    },
    {
      type  = "literal"
      name  = "WATSONX_SERVICE_URL"
      value = "https://${var.region}.ml.cloud.ibm.com"
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

  ce_secrets = merge(
    {
      # Secret for Watsonx
      "wx-ai" = {
        format = "generic"
        data = {
          "WATSONX_AI_APIKEY" = var.ibmcloud_api_key
        }
      }
    },
    # Secret for Container Registry
    {
      "${local.prefix}registry-secret" = {
        format = "registry"
        data = {
          username = "iamapikey"
          password = var.ibmcloud_api_key
          server   = module.cr_endpoint.container_registry_endpoint_private
        }
      }
    }
  )
  source_url   = "https://github.com/IBM/ai-agent-for-loan-risk"
  output_image = "${module.cr_endpoint.container_registry_endpoint_private}/${module.icr_namespace.namespace_name}/ai-agent-for-loan-risk"
  strategy     = "dockerfile"
  ce_app_name  = "ai-agent-for-loan-risk"
}

module "code_engine" {
  source            = "terraform-ibm-modules/code-engine/ibm"
  version           = "4.6.12"
  resource_group_id = module.resource_group.resource_group_id
  project_name      = "${local.prefix}project"
  secrets           = local.ce_secrets
}

##############################################################################
# Code Engine Build
##############################################################################

module "code_engine_build" {
  source                     = "terraform-ibm-modules/code-engine/ibm//modules/build"
  version                    = "4.6.12"
  name                       = "${local.prefix}ce-build"
  ibmcloud_api_key           = var.ibmcloud_api_key
  project_id                 = module.code_engine.project_id
  existing_resource_group_id = module.resource_group.resource_group_id
  source_type                = "git"
  output_image               = local.output_image
  output_secret              = "${local.prefix}registry-secret"
  source_url                 = local.source_url
  region                     = var.region
  strategy_type              = local.strategy
}

##############################################################################
# Code Engine Application
##############################################################################
module "code_engine_app" {
  source            = "terraform-ibm-modules/code-engine/ibm//modules/app"
  version           = "4.6.12"
  project_id        = module.code_engine.project_id
  name              = local.ce_app_name
  image_reference   = module.code_engine_build.output_image
  image_secret      = module.code_engine.secret["${local.prefix}registry-secret"].name
  run_env_variables = local.env_vars
}

# #############################################################################################################
