output "vm_public_ip" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Public IP address of the honeypot sensor VM"
}

output "monitoring_vm_public_ip" {
  value       = azurerm_public_ip.pip_monitoring.ip_address
  description = "Public IP address of the SecDash monitoring & operations VM"
}

output "snare_private_ip" {
  description = "The internal IP address of the snare honeypot sensor vm"
  value       = azurerm_public_ip.pip_snare.ip_address
}

output "cosmos_db_connection_string" {
  value       = azurerm_cosmosdb_account.cosmos_db.primary_mongodb_connection_string
  description = "The MongoDB connection string for Cosmos DB"
  sensitive   = true
}
