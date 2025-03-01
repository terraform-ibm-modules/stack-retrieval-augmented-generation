##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Event Notification
##############################################################################

module "event_notifications" {
  source            = "terraform-ibm-modules/event-notifications/ibm"
  version           = "1.18.7"
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-en"
  tags              = var.resource_tags
  plan              = "lite"
  service_endpoints = "public"
  region            = var.region
}

##############################################################################
# Secrets Manager
##############################################################################

module "secrets_manager" {
  source               = "terraform-ibm-modules/secrets-manager/ibm"
  version              = "1.24.1"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  secrets_manager_name = "${var.prefix}-secrets-manager" #tfsec:ignore:general-secrets-no-plaintext-exposure
  sm_service_plan      = "trial"
  sm_tags              = var.resource_tags
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

module "key_protect_all_inclusive" {
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.20.0"
  resource_group_id           = module.resource_group.resource_group_id
  key_protect_instance_name   = "${var.prefix}-kms"
  region                      = var.region
  resource_tags               = var.resource_tags
  key_protect_allowed_network = "public-and-private"
  key_ring_endpoint_type      = "private"
  key_endpoint_type           = "private"
}

module "kms_root_key" {
  source          = "terraform-ibm-modules/kms-key/ibm"
  kms_instance_id = module.key_protect_all_inclusive.kms_guid
  key_name        = "${var.prefix}-kms-root-key"
}

##############################################################################
# Security and Compliance Center
##############################################################################

module "cos" {
  source                     = "terraform-ibm-modules/cos/ibm"
  version                    = "8.15.11"
  cos_instance_name          = "${var.prefix}-cos"
  existing_kms_instance_guid = module.key_protect_all_inclusive.kms_guid
  retention_enabled          = false
  resource_group_id          = module.resource_group.resource_group_id
  bucket_name                = "${var.prefix}-cb"
  kms_key_crn                = module.kms_root_key.crn
}

module "security_and_compliance_center" {
  source                            = "terraform-ibm-modules/scc/ibm"
  version                           = "1.8.30"
  instance_name                     = "${var.prefix}-scc-instance"
  region                            = var.region
  resource_group_id                 = module.resource_group.resource_group_id
  resource_tags                     = var.resource_tags
  cos_bucket                        = module.cos.bucket_name
  cos_instance_crn                  = module.cos.cos_instance_id
  en_instance_crn                   = module.event_notifications.crn
  en_source_name                    = module.event_notifications.event_notification_instance_name
}
