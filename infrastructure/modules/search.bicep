@description('Name of the Azure Cognitive Search service')
param searchServiceName string

@description('Location for the search service')
param location string

@description('Tags for the search service')
param tags object

// Search Service
resource searchService 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: searchServiceName
  location: location
  tags: tags
  sku: {
    name: 'basic'  // Using basic tier for cost optimization
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
  }
}

// Outputs
output searchServiceName string = searchService.name
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'
