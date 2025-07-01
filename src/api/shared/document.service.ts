import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';
import { parse as parseDate } from 'date-fns';
import sanitize from 'sanitize-filename';
import { BlogMetadata } from './types';

const execAsync = promisify(exec);

export class DocumentService {
  public async convertWordToMarkdown(buffer: Buffer): Promise<string> {
    try {
      // Create a temporary file for the Word document
      const tempDir = path.join(__dirname, '../temp');
      const timestamp = new Date().getTime();
      const inputFile = path.join(tempDir, `input-${timestamp}.docx`);
      const outputFile = path.join(tempDir, `output-${timestamp}.md`);

      // Write the buffer to a temporary file
      await promisify(require('fs').writeFile)(inputFile, buffer);

      // Convert using pandoc
      await execAsync(`pandoc "${inputFile}" -f docx -t markdown -o "${outputFile}"`);

      // Read the converted markdown
      const markdown = await promisify(require('fs').readFile)(outputFile, 'utf8');

      // Clean up temporary files
      await Promise.all([
        promisify(require('fs').unlink)(inputFile),
        promisify(require('fs').unlink)(outputFile)
      ]);

      return markdown;
    } catch (error) {
      throw new Error(`Failed to convert Word document: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  public extractMetadata(content: string, filename: string): BlogMetadata {
    // Extract basic metadata from filename
    // Expected format: YYYY-MM-DD-title.docx
    const filenamePattern = /^(\d{4}-\d{2}-\d{2})-(.+)\.docx$/;
    const match = filenamePattern.exec(filename);
    
    let title = '';
    let created = new Date();
    
    if (match) {
      created = parseDate(match[1], 'yyyy-MM-dd', new Date());
      title = match[2].replace(/-/g, ' ').replace(/\b\w/g, char => char.toUpperCase());
    } else {
      title = path.basename(filename, '.docx')
        .replace(/-/g, ' ')
        .replace(/\b\w/g, char => char.toUpperCase());
    }

    // Extract category from first heading if available
    const categoryMatch = content.match(/^#\s+(.+)$/m);
    const category = categoryMatch ? categoryMatch[1].trim() : 'Uncategorized';

    // Extract tags from content (assuming they're marked with #tag format)
    const tagMatches = content.match(/#([a-zA-Z]\w+)/g) || [];
    const tags = tagMatches.map(tag => tag.substring(1));

    // Generate a sanitized ID from the title
    const id = sanitize(title.toLowerCase().replace(/\s+/g, '-'));

    return {
      id,
      title,
      content: content,
      category,
      tags: [...new Set(tags)], // Remove duplicates
      created,
      modified: new Date(),
      summary: this.generateSummary(content)
    };
  }

  private generateSummary(content: string, maxLength: number = 200): string {
    // Remove Markdown formatting
    let plainText = content
      .replace(/#+\s+/g, '') // Remove headers
      .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1') // Replace links with link text
      .replace(/[*_~`]/g, '') // Remove emphasis markers
      .replace(/\n+/g, ' ') // Replace newlines with spaces
      .trim();

    // Truncate to maxLength and add ellipsis if needed
    if (plainText.length > maxLength) {
      plainText = plainText.substring(0, maxLength).trim() + '...';
    }

    return plainText;
  }

  public validateDocument(filename: string, size: number): void {
    // Check file extension
    if (!filename.toLowerCase().endsWith('.docx')) {
      throw new Error('Only .docx files are supported');
    }

    // Check file size (e.g., max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    if (size > maxSize) {
      throw new Error('File size exceeds maximum limit of 10MB');
    }

    // Validate filename format
    const sanitizedFilename = sanitize(filename);
    if (sanitizedFilename !== filename) {
      throw new Error('Filename contains invalid characters');
    }
  }
}
