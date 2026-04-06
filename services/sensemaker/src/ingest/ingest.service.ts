import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { EmbeddingService } from '../embedding/embedding.service.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { AppConfig } from '../config/configuration.js';
import { NewsApiSource } from './sources/newsapi.source.js';
import { RssSource } from './sources/rss.source.js';
import { HackerNewsSource } from './sources/hackernews.source.js';
import type { RawArticle } from './sources/raw-article.interface.js';
import type { IngestResponse } from '@news-lab/types';

const COLLECTION = 'sensemaker_articles';

@Injectable()
export class IngestService {
  private readonly logger = new Logger(IngestService.name);

  constructor(
    private readonly embedding: EmbeddingService,
    private readonly firebase: FirebaseService,
    private readonly config: ConfigService<AppConfig, true>,
    private readonly newsApi: NewsApiSource,
    private readonly rss: RssSource,
    private readonly hn: HackerNewsSource,
  ) {}

  async ingest(): Promise<IngestResponse> {
    const { maxArticlesPerSource, snippetLength } = this.config.get('ingest', { infer: true });

    this.logger.log('Starting ingestion...');

    const [newsApiArticles, rssArticles, hnArticles] = await Promise.all([
      this.newsApi.fetch(maxArticlesPerSource, snippetLength),
      this.rss.fetch(maxArticlesPerSource, snippetLength),
      this.hn.fetch(maxArticlesPerSource, snippetLength),
    ]);

    const all = [...newsApiArticles, ...rssArticles, ...hnArticles];
    this.logger.log(`Fetched ${all.length} articles from all sources`);

    const deduplicated = this.deduplicateByUrl(all);
    const skipped = all.length - deduplicated.length;
    this.logger.log(`Deduplicated: ${skipped} duplicates removed, ${deduplicated.length} remaining`);

    let ingested = 0;
    for (const article of deduplicated) {
      try {
        await this.indexArticle(article);
        ingested++;
      } catch (err) {
        this.logger.warn(`Failed to index "${article.title}": ${err}`);
      }
    }

    const result: IngestResponse = {
      ingested,
      deduplicated: skipped,
      timestamp: new Date().toISOString(),
    };

    this.logger.log(`Ingestion complete: ${JSON.stringify(result)}`);
    return result;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  private deduplicateByUrl(articles: RawArticle[]): RawArticle[] {
    const seen = new Set<string>();
    return articles.filter((a) => {
      const key = this.urlKey(a.url);
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  private urlKey(url: string): string {
    return url.replace(/^https?:\/\/(www\.)?/, '').replace(/\/$/, '').toLowerCase();
  }

  private async indexArticle(article: RawArticle): Promise<void> {
    const docId = crypto.createHash('md5').update(article.url).digest('hex');

    // Skip articles already indexed
    const ref = this.firebase.db.collection(COLLECTION).doc(docId);
    const snap = await ref.get();
    if (snap.exists) return;

    const embeddingText = `${article.title} ${article.snippet}`.trim();
    const vector = await this.embedding.embed(embeddingText);

    await ref.set({
      title: article.title,
      source: article.source,
      url: article.url,
      publishedAt: article.publishedAt,
      snippet: article.snippet,
      embedding: FieldValue.vector(vector),
      indexedAt: new Date().toISOString(),
    });
  }
}
