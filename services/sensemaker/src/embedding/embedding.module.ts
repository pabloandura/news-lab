import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EMBEDDING_SERVICE } from './embedding.port.js';
import type { IEmbeddingService } from './embedding.port.js';
import { OllamaEmbeddingService } from './ollama-embedding.service.js';
import { VertexEmbeddingService } from './vertex-embedding.service.js';
import { AppConfig } from '../config/configuration.js';

@Global()
@Module({
  providers: [
    OllamaEmbeddingService,
    VertexEmbeddingService,
    {
      provide: EMBEDDING_SERVICE,
      useFactory: (
        config: ConfigService<AppConfig, true>,
        ollama: OllamaEmbeddingService,
        vertex: VertexEmbeddingService,
      ): IEmbeddingService =>
        config.get('nodeEnv', { infer: true }) === 'production' ? vertex : ollama,
      inject: [ConfigService, OllamaEmbeddingService, VertexEmbeddingService],
    },
  ],
  exports: [EMBEDDING_SERVICE],
})
export class EmbeddingModule {}
