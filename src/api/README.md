# Blog Processing Function App

This Azure Function App handles the processing of blog posts from Word documents to Markdown format, including image processing and search indexing.

## Prerequisites

- Node.js 16.x or later
- Azure Functions Core Tools v4.x
- Azure Storage Emulator or Azurite
- Pandoc (for Word document conversion)

## Setup

1. Install dependencies:
```bash
npm install
```

2. Install Pandoc:
- Windows: `winget install pandoc`
- macOS: `brew install pandoc`
- Linux: `sudo apt-get install pandoc`

3. Configure local settings:
   - Copy `local.settings.json` and update with your values:
     - `AzureWebJobsStorage`: Storage account connection string
     - `KEY_VAULT_URL`: Azure Key Vault URL
     - `SEARCH_ENDPOINT`: Azure Cognitive Search endpoint

## Development

1. Build the project:
```bash
npm run build
```

2. Start the function app locally:
```bash
npm start
```

## File Processing

The function processes Word documents (.docx) uploaded to the `raw-documents` container:

1. Document naming convention: `YYYY-MM-DD-title.docx`
2. Maximum file size: 10MB
3. Images are automatically extracted and processed
4. Content is converted to Markdown
5. Metadata is extracted from content and filename

## Outputs

- Processed Markdown files in the `processed-content` container
- Processed images in the `images` container
- Search index entries in Azure Cognitive Search
- Processing results in the `processed-documents` queue

## Testing

Upload a test document to the `raw-documents` container:

```bash
az storage blob upload \
  --container-name raw-documents \
  --file test.docx \
  --name 2025-06-24-test-post.docx \
  --connection-string "<storage-connection-string>"
```

## Deployment

The function app is deployed automatically via GitHub Actions when pushing to the main branch. Manual deployment:

```bash
func azure functionapp publish <function-app-name>
```

## Monitoring

- View logs in Application Insights
- Monitor blob containers for processed files
- Check queue messages for processing results

## Troubleshooting

1. Ensure Pandoc is installed and in PATH
2. Check storage emulator is running for local development
3. Verify all connection strings and endpoints in settings
4. Review Application Insights logs for detailed errors
