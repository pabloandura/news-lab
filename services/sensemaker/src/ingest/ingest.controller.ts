import { Controller, Post, HttpCode, HttpStatus, Logger } from '@nestjs/common';
import { IngestService } from './ingest.service.js';
import type { IngestResponse } from '@news-lab/types';

@Controller()
export class IngestController {
  private readonly logger = new Logger(IngestController.name);

  constructor(private readonly ingestService: IngestService) {}

  /**
   * POST /ingest
   * Triggered by Cloud Scheduler. Not exposed to the Flutter client.
   * Fetches all sources, generates embeddings, writes to Firestore.
   */
  @Post('ingest')
  @HttpCode(HttpStatus.OK)
  async ingest(): Promise<IngestResponse> {
    return this.ingestService.ingest();
  }
}
