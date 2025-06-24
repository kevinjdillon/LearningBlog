@description('Name of the static web app')
param staticAppName string

@description('Location for the static web app')
param location string

@description('Tags for the static web app')
param tags object

// Static Web App
resource staticApp 'Microsoft.Web/staticSites@2021-02-01' = {
  name: staticAppName
  location: location
  tags: tags
  sku: {
    name: 'Free'  // Using Free tier for development, upgrade to Standard for production
    tier: 'Free'
  }
  properties: {
    provider: 'GitHub'
    buildProperties: {
      skipGithubActionWorkflowGeneration: true  // We'll manage our own GitHub Actions workflow
    }
  }
}

// Create default configuration
resource staticAppConfig 'Microsoft.Web/staticSites/config@2021-02-01' = {
  parent: staticApp
  name: 'appsettings'
  properties: {
    // Add any app settings here
    SEARCH_API_ENDPOINT: ''  // Will be updated post-deployment
    STORAGE_API_ENDPOINT: ''  // Will be updated post-deployment
  }
}

// Outputs
output staticAppUrl string = staticApp.properties.defaultHostname
output staticAppName string = staticApp.name
