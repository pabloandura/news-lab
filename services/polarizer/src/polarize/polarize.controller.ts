import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { PolarizeService } from './polarize.service.js';
import { PolarizeRequestDto } from './dto/polarize-request.dto.js';
import type { PolarizeResponse } from '@news-lab/types';

@Controller()
export class PolarizeController {
  constructor(private readonly polarizeService: PolarizeService) {}

  /**
   * POST /polarize
   * Accepts article text, triggers async bias analysis, returns 202 immediately.
   * Result is written to Firestore fact_checks/{articleId}.biasReport.
   */
  @Post('polarize')
  @HttpCode(HttpStatus.ACCEPTED)
  runPolarize(@Body() dto: PolarizeRequestDto): PolarizeResponse {
    this.polarizeService.triggerAsync(dto);
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
