import { Global, Module } from '@nestjs/common';
import { VertexService } from './vertex.service.js';

@Global()
@Module({
  providers: [VertexService],
  exports: [VertexService],
})
export class VertexModule {}
