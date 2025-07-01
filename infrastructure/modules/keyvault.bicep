@description('Name of the key vault')
param keyVaultName string

@description('Location for the key vault')
param location string

@description('Tags for the key vault')
param tags object

@description('Principal ID of the function app for key vault access')
param functionAppPrincipalId string

@description('Storage account name for connection string')
param storageAccountName string

@description('Search service name for API key')
param searchServiceName string

// Get existing resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource searchService 'Microsoft.Search/searchServices@2021-04-01-preview' existing = {
  name: searchServiceName
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enableRbacAuthorization: false
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: functionAppPrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

// Initial Secrets
resource searchApiKey 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'SearchApiKey'
  properties: {
    contentType: 'text/plain'
    value: listAdminKeys(searchService.id, searchService.apiVersion).primaryKey
    attributes: {
      enabled: true
    }
  }
}

resource storageConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'StorageConnectionString'
  properties: {
    contentType: 'text/plain'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
    attributes: {
      enabled: true
    }
  }
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
