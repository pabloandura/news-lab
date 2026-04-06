import { Module } from '@nestjs/common';
import { ClaimBusterModule } from '../claimbuster/claimbuster.module.js';
import { FactCheckController } from './fact-check.controller.js';
import { FactCheckService } from './fact-check.service.js';

@Module({
  imports: [ClaimBusterModule],
  controllers: [FactCheckController],
  providers: [FactCheckService],
})
export class FactCheckModule {}
