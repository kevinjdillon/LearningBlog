import { SearchClient, SearchIndexClient, AzureKeyCredential } from '@azure/search-documents';
import { ConfigService } from './config.service';
import { BlogMetadata, SearchServiceConfig } from './types';

export class SearchService {
  private searchClient!: SearchClient<BlogMetadata>;
  private indexClient!: SearchIndexClient;
  private config: SearchServiceConfig;

  constructor() {
    this.config = ConfigService.getInstance().getSearchConfig();
  }

  public async initialize(): Promise<void> {
    const searchEndpoint = ConfigService.getInstance().getSearchEndpoint();
    const searchKey = await ConfigService.getInstance().getSearchApiKey();
    const credential = new AzureKeyCredential(searchKey);

    this.searchClient = new SearchClient<BlogMetadata>(
      searchEndpoint,
      this.config.indexName,
      credential
    );

    this.indexClient = new SearchIndexClient(searchEndpoint, credential);
  }

  public async indexDocument(document: BlogMetadata): Promise<void> {
    try {
      await this.searchClient.uploadDocuments([document]);
    } catch (error) {
      throw new Error(`Failed to index document: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  public async searchDocuments(
    searchText: string,
    filters?: string,
    facets?: string[]
  ): Promise<{ results: BlogMetadata[]; facets: Record<string, Record<string, number>> }> {
    try {
      const searchResults = await this.searchClient.search(searchText, {
        facets,
        filter: filters,
        select: ['id', 'title', 'content', 'category', 'tags', 'created', 'modified', 'author', 'summary'],
        orderBy: ['created desc']
      });

      const results: BlogMetadata[] = [];
      const resultFacets: Record<string, Record<string, number>> = {};

      for await (const result of searchResults.results) {
        if (result.document) {
          results.push(result.document);
        }
      }

      // Process facets if any
      if (searchResults.facets) {
        for (const [key, values] of Object.entries(searchResults.facets)) {
          resultFacets[key] = {};
          for (const value of values) {
            if (value.value && typeof value.count === 'number') {
              resultFacets[key][String(value.value)] = value.count;
            }
          }
        }
      }

      return {
        results,
        facets: resultFacets
      };
    } catch (error) {
      throw new Error(`Search failed: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  public async getSuggestions(searchText: string): Promise<string[]> {
    try {
      const suggestResults = await this.searchClient.suggest(
        searchText,
        this.config.suggesterName,
        {
          select: ['title']
        }
      );

      return suggestResults.results.map(result => result.text);
    } catch (error) {
      throw new Error(`Failed to get suggestions: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  public async deleteDocument(id: string): Promise<void> {
    try {
      await this.searchClient.deleteDocuments([{ id } as BlogMetadata]);
    } catch (error) {
      throw new Error(`Failed to delete document: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
