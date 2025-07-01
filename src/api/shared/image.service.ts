import sharp from 'sharp';
import { ConfigService } from './config.service';
import { ProcessedImage, ImageServiceConfig } from './types';

export class ImageService {
  private config: ImageServiceConfig;

  constructor() {
    this.config = ConfigService.getInstance().getImageConfig();
  }

  public async processImage(buffer: Buffer, originalName: string): Promise<ProcessedImage> {
    const image = sharp(buffer);
    const metadata = await image.metadata();

    if (!metadata.width || !metadata.height || !metadata.format) {
      throw new Error('Invalid image metadata');
    }

    // Generate a unique name for the processed image
    const timestamp = new Date().getTime();
    const baseName = originalName.replace(/\.[^/.]+$/, '');
    const extension = metadata.format.toLowerCase();
    const processedName = `${baseName}-${timestamp}.${extension}`;
    const thumbnailName = `${baseName}-${timestamp}-thumb.${extension}`;

    // Process main image
    const processedImage = await image
      .resize(this.config.maxWidth, this.config.maxHeight, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .jpeg({ quality: this.config.quality })
      .toBuffer();

    // Create thumbnail
    const thumbnailImage = await image
      .resize(this.config.thumbnailWidth, this.config.thumbnailHeight, {
        fit: 'cover'
      })
      .jpeg({ quality: this.config.quality })
      .toBuffer();

    // Validate file type
    const contentType = `image/${metadata.format.toLowerCase()}`;
    if (!this.config.allowedTypes.includes(contentType)) {
      throw new Error(`Unsupported image type: ${contentType}`);
    }

    return {
      originalName,
      processedName,
      thumbnailName,
      contentType,
      size: processedImage.length,
      dimensions: {
        width: metadata.width,
        height: metadata.height
      }
    };
  }

  public validateContentType(contentType: string): boolean {
    return this.config.allowedTypes.includes(contentType.toLowerCase());
  }

  public async extractImagesFromDocx(buffer: Buffer): Promise<Buffer[]> {
    // TODO: Implement DOCX image extraction
    // This will require additional library support
    return [];
  }
}
