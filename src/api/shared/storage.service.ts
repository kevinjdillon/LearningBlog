import { BlobServiceClient, ContainerClient } from '@azure/storage-blob';
import { ConfigService } from './config.service';
import { DocumentServiceConfig } from './types';

export class StorageService {
  private blobServiceClient!: BlobServiceClient;
  private config: DocumentServiceConfig;
  private rawContainer!: ContainerClient;
  private processedContainer!: ContainerClient;
  private imageContainer!: ContainerClient;

  constructor() {
    this.config = ConfigService.getInstance().getDocumentConfig();
  }

  public async initialize(): Promise<void> {
    const connectionString = await ConfigService.getInstance().getStorageConnectionString();
    this.blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
    
    // Get container clients
    this.rawContainer = this.blobServiceClient.getContainerClient(this.config.rawContainer);
    this.processedContainer = this.blobServiceClient.getContainerClient(this.config.processedContainer);
    this.imageContainer = this.blobServiceClient.getContainerClient(this.config.imageContainer);
  }

  public async uploadRawDocument(content: Buffer, filename: string): Promise<string> {
    const blockBlobClient = this.rawContainer.getBlockBlobClient(filename);
    await blockBlobClient.upload(content, content.length);
    return blockBlobClient.url;
  }

  public async downloadRawDocument(filename: string): Promise<Buffer> {
    const blockBlobClient = this.rawContainer.getBlockBlobClient(filename);
    const downloadResponse = await blockBlobClient.download(0);
    
    if (!downloadResponse.readableStreamBody) {
      throw new Error('No readable stream returned from blob download');
    }

    // Convert stream to buffer
    const chunks: Buffer[] = [];
    for await (const chunk of downloadResponse.readableStreamBody) {
      chunks.push(Buffer.from(chunk));
    }
    return Buffer.concat(chunks);
  }

  public async uploadProcessedContent(content: string, filename: string): Promise<string> {
    const blockBlobClient = this.processedContainer.getBlockBlobClient(filename);
    await blockBlobClient.upload(content, content.length, {
      blobHTTPHeaders: { blobContentType: 'text/markdown' }
    });
    return blockBlobClient.url;
  }

  public async uploadImage(content: Buffer, filename: string, contentType: string): Promise<string> {
    const blockBlobClient = this.imageContainer.getBlockBlobClient(filename);
    await blockBlobClient.upload(content, content.length, {
      blobHTTPHeaders: { blobContentType: contentType }
    });
    return blockBlobClient.url;
  }

  public async deleteRawDocument(filename: string): Promise<void> {
    const blockBlobClient = this.rawContainer.getBlockBlobClient(filename);
    await blockBlobClient.delete();
  }

  public async listRawDocuments(): Promise<string[]> {
    const filenames: string[] = [];
    for await (const blob of this.rawContainer.listBlobsFlat()) {
      filenames.push(blob.name);
    }
    return filenames;
  }
}
