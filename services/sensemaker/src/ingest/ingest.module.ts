import { Module } from '@nestjs/common';
import { IngestController } from './ingest.controller.js';
import { IngestService } from './ingest.service.js';
import { NewsApiSource } from './sources/newsapi.source.js';
import { RssSource } from './sources/rss.source.js';
import { HackerNewsSource } from './sources/hackernews.source.js';

@Module({
  controllers: [IngestController],
  providers: [IngestService, NewsApiSource, RssSource, HackerNewsSource],
})
export class IngestModule {}
