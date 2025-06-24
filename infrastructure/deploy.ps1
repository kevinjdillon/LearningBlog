param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'prod')]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-blog-$EnvironmentName"
)

# Ensure Az module is installed
if (-not (Get-Module -ListAvailable Az)) {
    Write-Error "Az PowerShell module is required but not installed. Please install it using: Install-Module -Name Az -AllowClobber -Scope CurrentUser"
    exit 1
}

# Check if logged in to Azure
$context = Get-AzContext
if (-not $context) {
    Write-Host "Not logged in to Azure. Initiating login..."
    Connect-AzAccount
}

# Create or update resource group
Write-Host "Creating/updating resource group '$ResourceGroupName' in location '$Location'..."
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# Deploy Bicep template
$templateFile = Join-Path $PSScriptRoot "main.bicep"
$parameterFile = Join-Path $PSScriptRoot "parameters/$EnvironmentName.parameters.json"

Write-Host "Deploying infrastructure to $EnvironmentName environment..."
Write-Host "Using template: $templateFile"
Write-Host "Using parameters: $parameterFile"

$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $templateFile `
    -TemplateParameterFile $parameterFile `
    -Verbose

if ($deployment.ProvisioningState -eq "Succeeded") {
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    
    # Output important values
    Write-Host "`nDeployment Outputs:"
    Write-Host "Static Web App URL: $($deployment.Outputs.staticAppUrl.Value)"
    Write-Host "Function App Name: $($deployment.Outputs.functionAppName.Value)"
    Write-Host "Storage Account Name: $($deployment.Outputs.storageAccountName.Value)"
    Write-Host "Key Vault Name: $($deployment.Outputs.keyVaultName.Value)"
    
} else {
    Write-Error "Deployment failed with state: $($deployment.ProvisioningState)"
    exit 1
}
