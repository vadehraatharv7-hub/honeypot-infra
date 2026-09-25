output "vm_public_ip" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Public IP address of the honeypot sensor VM"
}

output "monitoring_vm_public_ip" {
  value       = azurerm_public_ip.pip_monitoring.ip_address
  description = "Public IP address of the SecDash monitoring & operations VM"
}

output "database_private_ip" {
  description = "The internal IP address of the isolated Database VM (Redis & MongoDB)"
  value       = azurerm_linux_virtual_machine.db_vm.private_ip_address
}
