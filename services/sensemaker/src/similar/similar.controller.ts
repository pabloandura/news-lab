import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { SimilarService } from './similar.service.js';
import { SimilarRequestDto } from './dto/similar-request.dto.js';
import type { SimilarResponse } from '@news-lab/types';

@Controller()
export class SimilarController {
  constructor(private readonly similarService: SimilarService) {}

  /**
   * POST /similar
   * User-triggered. Returns top-N semantically similar articles synchronously.
   */
  @Post('similar')
  @HttpCode(HttpStatus.OK)
  findSimilar(@Body() dto: SimilarRequestDto): Promise<SimilarResponse> {
    return this.similarService.findSimilar(dto);
  }

  /**
   * GET /health
   * Used by Cloud Run for deployment health checks.
   */
  @Get('health')
  health(): { status: string } {
    return { status: 'ok' };
  }
}
