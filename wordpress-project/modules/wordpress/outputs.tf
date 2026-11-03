output "user_data" {
  description = "Bootstrap script used to install and configure WordPress."
  value       = local.user_data
  sensitive   = true
}
