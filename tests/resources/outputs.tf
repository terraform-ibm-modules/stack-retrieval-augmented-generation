output "resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "Resource group name"
}

output "region" {
  value       = var.region
  description = "Region"
}

output "prefix" {
  value       = var.prefix
  description = "Prefix"
}

output "resource_group_id" {
  value       = module.resource_group.resource_group_id
  description = "Resource group ID"
}

output "event_notifications_instance_crn" {
  value       = module.event_notifications.crn
  description = "CRN of created event notifications"
}

output "secrets_manager_instance_crn" {
  value       = module.secrets_manager.secrets_manager_crn
  description = "CRN of created secret manager instance"
}

output "kms_instance_crn" {
  value       = module.key_protect_all_inclusive.key_protect_crn
  description = "CRN of created kms instance"
}
