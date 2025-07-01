// Main deployment template for blog infrastructure

@description('Environment name (dev or prod)')
param environmentName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags for all resources')
param tags object = {
  environment: environmentName
  project: 'blog'
}

// Resource name variables
var storageAccountName = 'stblog${environmentName}${uniqueString(resourceGroup().id)}'
var functionAppName = 'func-blog-${environmentName}-${uniqueString(resourceGroup().id)}'
var searchServiceName = 'srch${environmentName}${take(uniqueString(resourceGroup().id), 8)}'
var keyVaultName = 'kv-blog${environmentName}${take(uniqueString(resourceGroup().id), 5)}'
var staticAppName = 'stapp-blog-${environmentName}'
var appInsightsName = 'appi-blog-${environmentName}'

// Storage Account
module storageModule 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
  }
}

// Function App
module functionModule 'modules/function.bicep' = {
  name: 'functionDeployment'
  params: {
    functionAppName: functionAppName
    storageAccountName: storageModule.outputs.storageAccountName
    location: location
    tags: tags
    appInsightsName: appInsightsName
  }
  dependsOn: [
    storageModule
  ]
}

// Search Service
module searchModule 'modules/search.bicep' = {
  name: 'searchDeployment'
  params: {
    searchServiceName: searchServiceName
    location: location
    tags: tags
  }
}

// Key Vault
module keyVaultModule 'modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    functionAppPrincipalId: functionModule.outputs.functionAppPrincipalId
    storageAccountName: storageModule.outputs.storageAccountName
    searchServiceName: searchServiceName
  }
  dependsOn: [
    functionModule
    searchModule
    storageModule
  ]
}

// Static Web App
module staticAppModule 'modules/staticapp.bicep' = {
  name: 'staticAppDeployment'
  params: {
    staticAppName: staticAppName
    location: location
    tags: tags
  }
}

// Application Insights
module monitoringModule 'modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    tags: tags
  }
}

// Outputs
output storageAccountName string = storageModule.outputs.storageAccountName
output functionAppName string = functionModule.outputs.functionAppName
output searchServiceName string = searchModule.outputs.searchServiceName
output staticAppUrl string = staticAppModule.outputs.staticAppUrl
output keyVaultName string = keyVaultModule.outputs.keyVaultName
