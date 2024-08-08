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

output "event_notification_instance_crn" {
  value       = module.event_notifications.crn
  description = "CRN of created event notification"
}

output "secrets_manager_instance_crn" {
  value       = module.secrets_manager.secrets_manager_crn
  description = "CRN of created secret manager instance"
}
