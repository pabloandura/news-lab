import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppConfig } from '../config/configuration.js';
import { IEmbeddingService } from './embedding.port.js';

@Injectable()
export class OllamaEmbeddingService implements IEmbeddingService, OnApplicationBootstrap {
  private readonly logger = new Logger(OllamaEmbeddingService.name);
  private ollamaHost = '';
  private ollamaModel = '';

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    const ollama = this.config.get('ollama', { infer: true });
    this.ollamaHost = ollama.host.replace(/\/$/, '');
    this.ollamaModel = ollama.model;
    this.logger.log(`Embeddings: Ollama @ ${this.ollamaHost} (model=${this.ollamaModel})`);
  }

  async embed(text: string): Promise<number[]> {
    const res = await fetch(`${this.ollamaHost}/api/embeddings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: this.ollamaModel, prompt: text }),
    });
    if (!res.ok) {
      throw new Error(`Ollama embeddings failed: ${res.status} ${res.statusText}`);
    }
    const data = (await res.json()) as { embedding: number[] };
    return data.embedding;
  }
}
