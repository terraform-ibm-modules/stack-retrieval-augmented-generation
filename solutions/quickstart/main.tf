##############################################################################################################
# Locals Block
##############################################################################################################

locals {

  prefix = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
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
  service_endpoints        = local.service_endpoints
  member_host_flavor       = "multitenant"
  deletion_protection      = false
  service_credential_names = local.es_credentials
}

resource "time_sleep" "wait" {
  depends_on      = [module.icd_elasticsearch]
  create_duration = "11m"
}

// Create Elastic search index
resource "elasticsearch_index" "es_create_index" {
  provider           = elasticsearch.ibm_es
  depends_on         = [time_sleep.wait]
  name               = local.es_index_name
  number_of_shards   = 1
  number_of_replicas = 1
  force_destroy      = true
}

##############################################################################################################
# Code Engine
##############################################################################################################

module "code_engine" {
  source            = "terraform-ibm-modules/code-engine/ibm"
  version           = "4.6.4"
  resource_group_id = module.resource_group.resource_group_id
  project_name      = "${local.prefix}project"
}

##############################################################################################################
