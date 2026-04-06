import { Injectable, Logger } from '@nestjs/common';
import { XMLParser } from 'fast-xml-parser';
import type { RawArticle } from './raw-article.interface.js';

const RSS_FEEDS: Array<{ source: string; url: string }> = [
  { source: 'BBC News', url: 'http://feeds.bbci.co.uk/news/rss.xml' },
  { source: 'Reuters', url: 'https://feeds.reuters.com/reuters/topNews' },
  { source: 'AP News', url: 'https://rsshub.app/apnews/topics/apf-topnews' },
  { source: 'Al Jazeera', url: 'https://www.aljazeera.com/xml/rss/all.xml' },
];

interface RssItem {
  title?: string;
  link?: string;
  pubDate?: string;
  description?: string;
}

interface RssChannel {
  item?: RssItem | RssItem[];
}

interface RssFeed {
  rss?: { channel?: RssChannel };
  feed?: { entry?: RssItem | RssItem[] };
}

@Injectable()
export class RssSource {
  private readonly logger = new Logger(RssSource.name);
  private readonly parser = new XMLParser({ ignoreAttributes: false });

  async fetch(maxPerFeed: number, snippetLength: number): Promise<RawArticle[]> {
    const results: RawArticle[] = [];

    for (const feed of RSS_FEEDS) {
      try {
        const articles = await this.fetchFeed(feed.source, feed.url, maxPerFeed, snippetLength);
        results.push(...articles);
      } catch (err) {
        this.logger.warn(`Failed to fetch RSS feed ${feed.source}: ${err}`);
      }
    }

    return results;
  }

  private async fetchFeed(
    source: string,
    url: string,
    maxResults: number,
    snippetLength: number,
  ): Promise<RawArticle[]> {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'news-lab-sensemaker/1.0' },
      signal: AbortSignal.timeout(8000),
    });

    if (!res.ok) {
      this.logger.warn(`RSS ${source}: HTTP ${res.status}`);
      return [];
    }

    const xml = await res.text();
    const parsed = this.parser.parse(xml) as RssFeed;

    const rawItems = parsed.rss?.channel?.item ?? parsed.feed?.entry ?? [];
    const items: RssItem[] = Array.isArray(rawItems) ? rawItems : [rawItems];

    return items
      .slice(0, maxResults)
      .filter((item) => item.title && item.link)
      .map((item) => ({
        title: String(item.title!),
        source,
        url: String(item.link!),
        publishedAt: item.pubDate ? new Date(item.pubDate).toISOString() : new Date().toISOString(),
        snippet: this.stripHtml(String(item.description ?? '')).slice(0, snippetLength),
      }));
  }

  private stripHtml(html: string): string {
    return html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  }
}
