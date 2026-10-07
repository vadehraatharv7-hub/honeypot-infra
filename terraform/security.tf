resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-honeypot-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # checkov:skip=CKV_AZURE_9:Port 22 is deliberately exposed to the internet as a Cowrie honeypot decoy sensor
  # checkov:skip=CKV_AZURE_10:Port 22 is open for decoy honeypot attack capture
  security_rule {
    name                       = "allow-decoy-port"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Admin-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22222"
    source_address_prefix      = var.admin_public_ip
    destination_address_prefix = "*"
  }

  # Allow Honeypot to send JSON logs to the Monitoring VM (Port 8081)
  security_rule {
    name                       = "Allow-Outbound-To-Monitoring"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.4"
  }

  # Prevent compromised honeypot from scanning or attacking other internal subnets
  security_rule {
    name                       = "Deny-Outbound-VNet"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.0.0/16"
  }
}

resource "azurerm_network_security_group" "nsg_monitoring" {
  name                = "nsg-monitoring-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow inbound logs strictly from the Honeypot subnet
  security_rule {
    name                       = "Allow-Backend-Ingestion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefixes    = ["10.0.1.0/24", "10.0.4.0/24"]
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "8081"
  }

  security_rule {
    name                       = "Allow-Admin-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.admin_public_ip
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22222"
  }

  # Allow your browser to view the SecDash web UI
  security_rule {
    name                       = "Allow-HTTP-Web"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.admin_public_ip
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
  }
}


resource "azurerm_network_security_group" "nsg_snare" {
  name                = "nsg-snare-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Web-Decoys"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Admin-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22222"
    source_address_prefix      = var.admin_public_ip
    destination_address_prefix = "*"
  }

  # Allow Snare to send JSON logs to the Monitoring VM
  security_rule {
    name                       = "Allow-Outbound-To-Monitoring"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = "10.0.2.4"
  }

  # Prevent compromised Snare from scanning internal subnets
  security_rule {
    name                       = "Deny-Outbound-VNet"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = "10.0.0.0/16"
  }
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "vm-database-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow Redis (6379) and MongoDB (27017) strictly from the Monitoring subnet
  security_rule {
    name                       = "Allow-Mongo-Redis-Internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["27017", "6379"]
    source_address_prefix      = azurerm_subnet.subnet_monitoring.address_prefixes[0]
    destination_address_prefix = "*"
  }

  # Allow SSH strictly from the Monitoring subnet (Jumpbox model)
  security_rule {
    name                       = "Allow-SSH-Internal"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.subnet_monitoring.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_asso" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nsg_asso_monitoring" {
  network_interface_id      = azurerm_network_interface.nic_monitoring.id
  network_security_group_id = azurerm_network_security_group.nsg_monitoring.id
}


resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_monitoring_nsg" {
  subnet_id                 = azurerm_subnet.subnet_monitoring.id
  network_security_group_id = azurerm_network_security_group.nsg_monitoring.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_snare_nsg" {
  subnet_id                 = azurerm_subnet.subnet_snare.id
  network_security_group_id = azurerm_network_security_group.nsg_snare.id
}

resource "azurerm_network_interface_security_group_association" "nsg_asso_snare" {
  network_interface_id      = azurerm_network_interface.nic_snare.id
  network_security_group_id = azurerm_network_security_group.nsg_snare.id
}

# Associate the DB NSG with the DB NIC
resource "azurerm_network_interface_security_group_association" "db_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.db_nic.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Associate the DB NSG directly to the Database Subnet (Best Practice / CKV2_AZURE_31)
resource "azurerm_subnet_network_security_group_association" "subnet_database_nsg" {
  subnet_id                 = azurerm_subnet.subnet_database.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

