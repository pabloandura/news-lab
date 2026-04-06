import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { FactCheckService } from './fact-check.service.js';
import { FactCheckRequestDto } from './dto/fact-check-request.dto.js';
import type { FactCheckResponse } from '@news-lab/types';

@Controller()
export class FactCheckController {
  constructor(private readonly factCheckService: FactCheckService) {}

  /**
   * POST /fact-check
   * Accepts article text, triggers async pipeline, returns 202 immediately.
   * Result is written to Firestore fact_checks/{articleId}.botCheck.
   */
  @Post('fact-check')
  @HttpCode(HttpStatus.ACCEPTED)
  runFactCheck(@Body() dto: FactCheckRequestDto): FactCheckResponse {
    this.factCheckService.triggerAsync(dto);
    return { status: 'processing', articleId: dto.articleId };
  }

  /**
   * GET /health
   * Used by Cloud Run for deployment health checks and automatic rollback.
   */
  @Get('health')
  health(): { status: string } {
    return { status: 'ok' };
  }
}
