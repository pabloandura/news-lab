import { Module } from '@nestjs/common';
import { SimilarController } from './similar.controller.js';
import { SimilarService } from './similar.service.js';

@Module({
  controllers: [SimilarController],
  providers: [SimilarService],
})
export class SimilarModule {}
