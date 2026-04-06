import { Module } from '@nestjs/common';
import { ClaimBusterService } from './claimbuster.service.js';

@Module({
  providers: [ClaimBusterService],
  exports: [ClaimBusterService],
})
export class ClaimBusterModule {}
