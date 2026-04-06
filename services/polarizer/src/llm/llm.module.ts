import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LLM_SERVICE } from './llm.port.js';
import type { ILlmService } from './llm.port.js';
import { OllamaLlmService } from './ollama-llm.service.js';
import { VertexLlmService } from './vertex-llm.service.js';
import { AppConfig } from '../config/configuration.js';

@Global()
@Module({
  providers: [
    OllamaLlmService,
    VertexLlmService,
    {
      provide: LLM_SERVICE,
      useFactory: (
        config: ConfigService<AppConfig, true>,
        ollama: OllamaLlmService,
        vertex: VertexLlmService,
      ): ILlmService =>
        config.get('nodeEnv', { infer: true }) === 'production' ? vertex : ollama,
      inject: [ConfigService, OllamaLlmService, VertexLlmService],
    },
  ],
  exports: [LLM_SERVICE],
})
export class LlmModule {}
