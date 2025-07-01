import { AzureFunction, Context } from '@azure/functions';
import { StorageService } from '../shared/storage.service';
import { ImageService } from '../shared/image.service';
import { DocumentService } from '../shared/document.service';
import { SearchService } from '../shared/search.service';
import { ProcessingResult } from '../shared/types';

const blobTrigger: AzureFunction = async function (context: Context, inputBlob: Buffer): Promise<void> {
    try {
        // Initialize services
        const storageService = new StorageService();
        const imageService = new ImageService();
        const documentService = new DocumentService();
        const searchService = new SearchService();

        await Promise.all([
            storageService.initialize(),
            searchService.initialize()
        ]);

        const filename = context.bindingData.name;
        context.log(`Processing document: ${filename}`);

        // Validate document
        documentService.validateDocument(filename, inputBlob.length);

        // Convert Word to Markdown
        const markdown = await documentService.convertWordToMarkdown(inputBlob);

        // Extract metadata
        const metadata = documentService.extractMetadata(markdown, filename);

        // Extract and process images
        const images = await imageService.extractImagesFromDocx(inputBlob);
        const processedImages = await Promise.all(
            images.map(async (imageBuffer, index) => {
                const imageFilename = `${metadata.id}-image-${index + 1}`;
                const processedImage = await imageService.processImage(imageBuffer, imageFilename);

                // Upload processed image and thumbnail
                await Promise.all([
                    storageService.uploadImage(imageBuffer, processedImage.processedName, processedImage.contentType),
                    storageService.uploadImage(imageBuffer, processedImage.thumbnailName, processedImage.contentType)
                ]);

                return processedImage;
            })
        );

        // Add image paths to metadata
        metadata.imagePaths = processedImages.map(img => img.processedName);

        // Upload processed content
        const markdownFilename = `${metadata.id}.md`;
        await storageService.uploadProcessedContent(markdown, markdownFilename);

        // Index the document
        await searchService.indexDocument(metadata);

        // Clean up the original document
        await storageService.deleteRawDocument(filename);

        const result: ProcessingResult = {
            metadata,
            content: markdown,
            images: processedImages
        };

        context.log('Document processed successfully:', result);
        
        // Set output binding
        context.bindings.outputDocument = result;

    } catch (error) {
        context.log.error('Error processing document:', error);
        throw error;
    }
};

export default blobTrigger;
