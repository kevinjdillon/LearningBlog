export interface BlogMetadata {
  id: string;
  title: string;
  content: string;
  category: string;
  tags: string[];
  created: Date;
  modified: Date;
  author?: string;
  summary?: string;
  imagePaths?: string[];
}

export interface ProcessedImage {
  originalName: string;
  processedName: string;
  thumbnailName: string;
  contentType: string;
  size: number;
  dimensions: {
    width: number;
    height: number;
  };
}

export interface ProcessingResult {
  metadata: BlogMetadata;
  content: string;
  images: ProcessedImage[];
}

export interface DocumentServiceConfig {
  rawContainer: string;
  processedContainer: string;
  imageContainer: string;
}

export interface ImageServiceConfig {
  maxWidth: number;
  maxHeight: number;
  thumbnailWidth: number;
  thumbnailHeight: number;
  quality: number;
  allowedTypes: string[];
}

export interface SearchServiceConfig {
  indexName: string;
  suggesterName: string;
}
