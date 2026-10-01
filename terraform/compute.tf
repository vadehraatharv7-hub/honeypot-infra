resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-honeypot"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_azure.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
  #!/bin/bash
  sed -i 's/^#*Port 22.*/Port 22222/' /etc/ssh/sshd_config
  systemctl restart sshd
  EOF
  )



}

resource "azurerm_linux_virtual_machine" "vm_monitoring" {
  name                            = "vm-monitoring"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_monitoring.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
  #!/bin/bash
  sed -i 's/^#*Port 22.*/Port 22222/' /etc/ssh/sshd_config
  systemctl restart sshd
  EOF
  )



}


resource "azurerm_linux_virtual_machine" "vm_snare" {
  name                            = "vm-snare"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_snare.id
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_azure.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
  #!/bin/bash
  sed -i 's/^#*Port 22.*/Port 22222/' /etc/ssh/sshd_config
  systemctl restart sshd
  EOF
  )

}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"
  content = templatefile("inventory.tftpl", {
    honeypot_ip   = azurerm_public_ip.pip.ip_address
    snare_ip      = azurerm_public_ip.pip_snare.ip_address
    monitoring_ip = azurerm_public_ip.pip_monitoring.ip_address
    cosmos_db_uri = azurerm_cosmosdb_account.cosmos_db.primary_mongodb_connection_string
  })
}

