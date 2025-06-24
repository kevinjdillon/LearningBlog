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

// Search Index
resource blogIndex 'Microsoft.Search/searchServices/indexes@2021-04-01-preview' = {
  parent: searchService
  name: 'blog-index'
  properties: {
    fields: [
      {
        name: 'id'
        type: 'Edm.String'
        key: true
        searchable: false
        sortable: false
      }
      {
        name: 'title'
        type: 'Edm.String'
        searchable: true
        sortable: true
        filterable: false
        facetable: false
      }
      {
        name: 'content'
        type: 'Edm.String'
        searchable: true
        sortable: false
        filterable: false
        facetable: false
      }
      {
        name: 'category'
        type: 'Edm.String'
        searchable: true
        sortable: true
        filterable: true
        facetable: true
      }
      {
        name: 'tags'
        type: 'Collection(Edm.String)'
        searchable: true
        sortable: false
        filterable: true
        facetable: true
      }
      {
        name: 'created'
        type: 'Edm.DateTimeOffset'
        searchable: false
        sortable: true
        filterable: true
        facetable: false
      }
      {
        name: 'modified'
        type: 'Edm.DateTimeOffset'
        searchable: false
        sortable: true
        filterable: true
        facetable: false
      }
    ]
    suggesters: [
      {
        name: 'blog-suggester'
        searchMode: 'analyzingInfixMatching'
        sourceFields: [
          'title'
        ]
      }
    ]
  }
}

// Outputs
output searchServiceName string = searchService.name
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'
output searchIndexName string = blogIndex.name
