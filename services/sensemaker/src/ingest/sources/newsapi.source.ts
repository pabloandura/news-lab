import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppConfig } from '../../config/configuration.js';
import type { RawArticle } from './raw-article.interface.js';

interface NewsApiArticle {
  title: string;
  source: { name: string };
  url: string;
  publishedAt: string;
  description: string | null;
  content: string | null;
}

interface NewsApiResponse {
  status: string;
  articles: NewsApiArticle[];
}

@Injectable()
export class NewsApiSource {
  private readonly logger = new Logger(NewsApiSource.name);

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  async fetch(maxResults: number, snippetLength: number): Promise<RawArticle[]> {
    const key = this.config.get('newsApi.key', { infer: true });
    if (!key) {
      this.logger.warn('NEWS_API_KEY not set — skipping NewsAPI source');
      return [];
    }

    const url = `https://newsapi.org/v2/top-headlines?language=en&pageSize=${Math.min(maxResults, 100)}&apiKey=${key}`;
    const res = await fetch(url);
    if (!res.ok) {
      this.logger.warn(`NewsAPI returned ${res.status} — skipping`);
      return [];
    }

    const data = (await res.json()) as NewsApiResponse;
    if (data.status !== 'ok') return [];

    return data.articles
      .filter((a) => a.title && a.url && !a.title.includes('[Removed]'))
      .map((a) => ({
        title: a.title,
        source: a.source.name,
        url: a.url,
        publishedAt: a.publishedAt,
        snippet: (a.description ?? a.content ?? '').slice(0, snippetLength),
      }));
  }
}
