locals {
  prefix = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
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
  version           = "10.4.0"
  resource_group_id = module.resource_group.resource_group_id
  cos_instance_name = "${local.prefix}cos"
  cos_plan          = "standard"
  cos_tags          = var.resource_tags
}

##############################################################################
# Key Protect
##############################################################################

locals {
  key_ring_name = "${local.prefix}keyring"
  key_name      = "${local.prefix}key"
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "5.3.3"
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
# Code Engine
##############################################################################################################



# Pass the existing application info


##############################################################################################################
# watsonx.ai
##############################################################################################################

module "watsonx_ai" {
  source                    = "terraform-ibm-modules/watsonx-ai/ibm"
  version                   = "2.8.8"
  region                    = var.region
  resource_group_id         = module.resource_group.resource_group_id
  resource_tags             = var.resource_tags
  project_name              = "${local.prefix}project-rag"
  watsonx_ai_studio_plan    = "professional-v1"
  watsonx_ai_runtime_plan   = "v2-professional"
  enable_cos_kms_encryption = true
  cos_instance_crn          = module.cos.cos_instance_crn
  cos_kms_key_crn           = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
}

##############################################################################################################
# Watson Discovery
##############################################################################################################

module "watson_discovery" {
  source                = "terraform-ibm-modules/watsonx-discovery/ibm"
  version               = "1.10.5"
  region                = var.region
  resource_group_id     = module.resource_group.resource_group_id
  resource_tags         = var.resource_tags
  plan                  = "plus"
  watson_discovery_name = "${local.prefix}discovery"
  service_endpoints     = "public-and-private"
}

##############################################################################################################
# watsonx Assistant
##############################################################################################################

module "watsonx_assistant" {
  source                 = "terraform-ibm-modules/watsonx-assistant/ibm"
  version                = "1.4.6"
  region                 = var.region
  resource_group_id      = module.resource_group.resource_group_id
  resource_tags          = var.resource_tags
  plan                   = "enterprise"
  watsonx_assistant_name = "${local.prefix}assistant"
  service_endpoints      = "public-and-private"
}

##############################################################################################################
# watsonx.data
##############################################################################################################

##############################################################################################################
# watsonx.governance
##############################################################################################################


##############################################################################################################
# Elastic search
##############################################################################################################

locals {
  es_credentials = {
    "elasticsearch_admin" : "Administrator",
    "elasticsearch_operator" : "Operator",
    "elasticsearch_viewer" : "Viewer",
    "elasticsearch_editor" : "Editor",
  }
}

module "icd_elasticsearch" {
  source                   = "terraform-ibm-modules/icd-elasticsearch/ibm"
  version                  = "2.3.28"
  resource_group_id        = module.resource_group.resource_group_id
  name                     = "${local.prefix}data-store"
  region                   = var.region
  elasticsearch_version    = "8.12"
  tags                     = var.resource_tags
  service_endpoints        = "public-and-private"
  member_host_flavor       = "multitenant"
  deletion_protection      = false
  service_credential_names = local.es_credentials
}

##############################################################################################################
# Event Notifications
##############################################################################################################


##############################################################################################################
# Secrets Manager
##############################################################################################################


##############################################################################################################
# Cloud Logs
##############################################################################################################

##############################################################################################################
# Cloud Monitoring
##############################################################################################################

##############################################################################################################
# App Configuration
##############################################################################################################

##############################################################################################################
# SCC WP
##############################################################################################################

##############################################################################################################
