# Generate a random suffix since Cosmos DB account names must be globally unique
resource "random_string" "cosmos_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Azure Cosmos DB Account (Lifetime Free Tier)
resource "azurerm_cosmosdb_account" "cosmos_db" {
  name                = "cosmos-honeypot-${random_string.cosmos_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  # Activates the lifetime 1,000 RU/s and 25GB free tier
  free_tier_enabled             = true
  public_network_access_enabled = false

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

# Cosmos DB MongoDB Database
resource "azurerm_cosmosdb_mongo_database" "mongo_db" {
  name                = "honeypot_db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos_db.name
  throughput          = 400 # Covered entirely by the free tier
}

resource "azurerm_private_dns_zone" "cosmos_dns" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = "pe-cosmos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_database.id

  private_service_connection {
    name                           = "psc-cosmos"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos_db.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_dns.id]
  }
}
