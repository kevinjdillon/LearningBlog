param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'prod')]
    [string]$EnvironmentName
)

# Check prerequisites
if (-not (Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Error "Azure Functions Core Tools is not installed. Please install it first."
    exit 1
}

if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Error "Pandoc is not installed. Please install it first."
    exit 1
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js and npm are not installed. Please install them first."
    exit 1
}

if (-not (Get-InstalledModule -Name Az -ErrorAction SilentlyContinue)) {
    Write-Error "Az PowerShell module is not installed. Please install it first."
    exit 1
}

try {
    # Ensure we're logged into Azure
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged into Azure. Please run Connect-AzAccount first."
    }

# Install dependencies and build
    Write-Host "Installing dependencies..."
    npm install
    npm install --platform=win32 --arch=ia32 sharp

    Write-Host "Building project..."
    npm run build

# Get function app name and details from Azure
$functionApp = Get-AzFunctionApp -ResourceGroupName "rg-blog-$EnvironmentName" | Where-Object { $_.Name -like "func-blog-$EnvironmentName*" }
$functionAppName = $functionApp.Name
$functionAppLocation = $functionApp.Location

    if (-not $functionAppName) {
        throw "Function app not found in resource group rg-blog-$EnvironmentName"
    }

    # Deploy to Azure
    Write-Host "Deploying to $functionAppName..."
    $publishZip = "publish.zip"
    
    # Create a deployment package
    if (Test-Path $publishZip) {
        Remove-Item $publishZip
    }
    
    Compress-Archive -Path ".\*" -DestinationPath $publishZip -Force
    
    # Deploy using Azure PowerShell
    Write-Host "Publishing function app..."
    Publish-AzWebApp -ResourceGroupName "rg-blog-$EnvironmentName" `
                    -Name $functionAppName `
                    -ArchivePath (Get-Item $publishZip).FullName `
                    -Force
    
    # Clean up
    Remove-Item $publishZip

    Write-Host "Deployment complete. Creating test document..."

    # Get storage account details
    $storageAccount = (Get-AzStorageAccount -ResourceGroupName "rg-blog-$EnvironmentName" | Where-Object { $_.StorageAccountName -like "stblog$EnvironmentName*" })
    if (-not $storageAccount) {
        throw "Storage account not found in resource group rg-blog-$EnvironmentName"
    }
    $storageContext = $storageAccount.Context

    # Create a sample test document
    $testDoc = @"
# Test Blog Post

This is a test blog post to verify the document processing functionality.

## Features Tested

1. Markdown conversion
2. Metadata extraction
3. Search indexing

#testing #automation
"@

    # Create temporary files
    $tempMdFile = [System.IO.Path]::GetTempFileName()
    $testDocPath = [System.IO.Path]::GetTempFileName() + ".docx"
    
    try {
        # Save markdown content
        Set-Content -Path $tempMdFile -Value $testDoc -Encoding UTF8

        # Convert markdown to Word using pandoc
        Write-Host "Converting test document to Word format..."
        pandoc $tempMdFile -f markdown -t docx -o $testDocPath

        # Upload test document to blob storage
        $blobName = "$(Get-Date -Format 'yyyy-MM-dd')-test-post.docx"
        Write-Host "Uploading test document as $blobName..."
        Set-AzStorageBlobContent `
            -Context $storageContext `
            -Container "raw-documents" `
            -File $testDocPath `
            -Blob $blobName `
            -Force

        Write-Host "Test document uploaded. Monitor the function app logs to see processing results."
    }
    finally {
        # Clean up temporary files
        if (Test-Path $tempMdFile) {
            Remove-Item $tempMdFile -ErrorAction SilentlyContinue
        }
        if (Test-Path $testDocPath) {
            Remove-Item $testDocPath -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Deployment and testing complete. Check the Azure portal for results."
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
    Write-Host "Full error details: $_"
    exit 1
}
