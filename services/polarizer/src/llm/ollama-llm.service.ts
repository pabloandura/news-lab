import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppConfig } from '../config/configuration.js';
import { ILlmService } from './llm.port.js';

@Injectable()
export class OllamaLlmService implements ILlmService, OnApplicationBootstrap {
  private readonly logger = new Logger(OllamaLlmService.name);
  private ollamaHost = '';
  private ollamaModel = '';

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    const ollama = this.config.get('ollama', { infer: true });
    this.ollamaHost = ollama.host.replace(/\/$/, '');
    this.ollamaModel = ollama.model;
    this.logger.log(`LLM: Ollama @ ${this.ollamaHost} (model=${this.ollamaModel})`);
  }

  async generate(prompt: string): Promise<string> {
    const res = await fetch(`${this.ollamaHost}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: this.ollamaModel,
        prompt,
        stream: false,
        format: 'json',
      }),
    });
    if (!res.ok) {
      throw new Error(`Ollama request failed: ${res.status} ${res.statusText}`);
    }
    const data = (await res.json()) as { response: string };
    return data.response;
  }
}
