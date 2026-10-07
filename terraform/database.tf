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
  public_network_access_enabled = true
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = azurerm_subnet.subnet.id
  }

  virtual_network_rule {
    id = azurerm_subnet.subnet_snare.id
  }

  virtual_network_rule {
    id = azurerm_subnet.subnet_monitoring.id
  }

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