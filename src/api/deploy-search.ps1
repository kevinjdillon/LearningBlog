param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'prod')]
    [string]$EnvironmentName
)

try {
    # Get search service details using Azure CLI
    Write-Host "Getting search service details..."
    $searchService = (az search service list --resource-group "rg-blog-$EnvironmentName" | ConvertFrom-Json) | 
        Where-Object { $_.name -like "srch$EnvironmentName*" }

    if (-not $searchService) {
        throw "Search service not found in resource group rg-blog-$EnvironmentName"
    }

    # Get admin key using Azure CLI REST API
    Write-Host "Getting search service admin key..."
    $adminKey = (az rest --method post `
        --uri "https://management.azure.com$($searchService.id)/listAdminKeys?api-version=2020-08-01" `
        --query "primaryKey" `
        --output tsv)

    if (-not $adminKey) {
        throw "Failed to retrieve admin key for search service"
    }

    # Define the index schema
    $indexDefinition = @{
        name = "blog-index"
        fields = @(
            @{
                name = "id"
                type = "Edm.String"
                key = $true
                searchable = $false
                sortable = $false
            },
            @{
                name = "title"
                type = "Edm.String"
                searchable = $true
                sortable = $true
                filterable = $false
                facetable = $false
            },
            @{
                name = "content"
                type = "Edm.String"
                searchable = $true
                sortable = $false
                filterable = $false
                facetable = $false
            },
            @{
                name = "category"
                type = "Edm.String"
                searchable = $true
                sortable = $true
                filterable = $true
                facetable = $true
            },
            @{
                name = "tags"
                type = "Collection(Edm.String)"
                searchable = $true
                sortable = $false
                filterable = $true
                facetable = $true
            },
            @{
                name = "created"
                type = "Edm.DateTimeOffset"
                searchable = $false
                sortable = $true
                filterable = $true
                facetable = $false
            },
            @{
                name = "modified"
                type = "Edm.DateTimeOffset"
                searchable = $false
                sortable = $true
                filterable = $true
                facetable = $false
            },
            @{
                name = "author"
                type = "Edm.String"
                searchable = $true
                sortable = $true
                filterable = $true
                facetable = $true
            },
            @{
                name = "summary"
                type = "Edm.String"
                searchable = $true
                sortable = $false
                filterable = $false
                facetable = $false
            },
            @{
                name = "imagePaths"
                type = "Collection(Edm.String)"
                searchable = $false
                sortable = $false
                filterable = $false
                facetable = $false
            }
        )
        suggesters = @(
            @{
                name = "blog-suggester"
                searchMode = "analyzingInfixMatching"
                sourceFields = @("title", "category", "tags")
            }
        )
    }

    # Convert to JSON
    $indexJson = $indexDefinition | ConvertTo-Json -Depth 10

    # Create or update the index
    Write-Host "Creating/updating search index..."
    $searchEndpoint = "https://$($searchService.Name).search.windows.net"
    
    $headers = @{
        'api-key' = $adminKey
        'Content-Type' = 'application/json'
    }

    $response = Invoke-RestMethod `
        -Uri "$searchEndpoint/indexes/blog-index?api-version=2021-04-30-Preview" `
        -Headers $headers `
        -Method Put `
        -Body $indexJson

    Write-Host "Search index deployed successfully."
    return $response

}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
    Write-Host "Full error details: $_"
    exit 1
}
