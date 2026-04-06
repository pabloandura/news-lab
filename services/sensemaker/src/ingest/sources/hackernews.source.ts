import { Injectable, Logger } from '@nestjs/common';
import type { RawArticle } from './raw-article.interface.js';

interface HnHit {
  title: string;
  url: string | null;
  created_at: string;
  story_text: string | null;
}

interface HnResponse {
  hits: HnHit[];
}

@Injectable()
export class HackerNewsSource {
  private readonly logger = new Logger(HackerNewsSource.name);

  async fetch(maxResults: number, snippetLength: number): Promise<RawArticle[]> {
    const url = `https://hn.algolia.com/api/v1/search?tags=story&hitsPerPage=${maxResults}&numericFilters=points>50`;

    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
      if (!res.ok) {
        this.logger.warn(`Hacker News API returned ${res.status} — skipping`);
        return [];
      }

      const data = (await res.json()) as HnResponse;

      return data.hits
        .filter((h) => h.title && h.url)
        .map((h) => ({
          title: h.title,
          source: 'Hacker News',
          url: h.url!,
          publishedAt: h.created_at,
          snippet: (h.story_text ?? '').slice(0, snippetLength),
        }));
    } catch (err) {
      this.logger.warn(`Failed to fetch Hacker News: ${err}`);
      return [];
    }
  }
}
