import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import { DocumentServiceConfig, ImageServiceConfig, SearchServiceConfig } from './types';

export class ConfigService {
  private static instance: ConfigService;
  private keyVaultClient: SecretClient;
  private cachedSecrets: Map<string, string> = new Map();

  private constructor() {
    const credential = new DefaultAzureCredential();
    const keyVaultUrl = process.env.KEY_VAULT_URL;
    if (!keyVaultUrl) {
      throw new Error('KEY_VAULT_URL environment variable is not set');
    }
    this.keyVaultClient = new SecretClient(keyVaultUrl, credential);
  }

  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  private async getSecret(secretName: string): Promise<string> {
    if (this.cachedSecrets.has(secretName)) {
      return this.cachedSecrets.get(secretName)!;
    }

    const secret = await this.keyVaultClient.getSecret(secretName);
    if (!secret.value) {
      throw new Error(`Secret ${secretName} not found`);
    }

    this.cachedSecrets.set(secretName, secret.value);
    return secret.value;
  }

  public async getStorageConnectionString(): Promise<string> {
    return this.getSecret('StorageConnectionString');
  }

  public async getSearchApiKey(): Promise<string> {
    return this.getSecret('SearchApiKey');
  }

  public getDocumentConfig(): DocumentServiceConfig {
    return {
      rawContainer: 'raw-documents',
      processedContainer: 'processed-content',
      imageContainer: 'images'
    };
  }

  public getImageConfig(): ImageServiceConfig {
    return {
      maxWidth: 1200,
      maxHeight: 800,
      thumbnailWidth: 300,
      thumbnailHeight: 200,
      quality: 80,
      allowedTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    };
  }

  public getSearchConfig(): SearchServiceConfig {
    const searchEndpoint = process.env.SEARCH_ENDPOINT;
    if (!searchEndpoint) {
      throw new Error('SEARCH_ENDPOINT environment variable is not set');
    }

    return {
      indexName: 'blog-index',
      suggesterName: 'blog-suggester'
    };
  }

  public getSearchEndpoint(): string {
    const searchEndpoint = process.env.SEARCH_ENDPOINT;
    if (!searchEndpoint) {
      throw new Error('SEARCH_ENDPOINT environment variable is not set');
    }
    return searchEndpoint;
  }
}
