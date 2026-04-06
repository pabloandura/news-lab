import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VertexAI, GenerativeModel } from '@google-cloud/vertexai';
import { AppConfig } from '../config/configuration.js';

@Injectable()
export class LlmService implements OnApplicationBootstrap {
  private readonly logger = new Logger(LlmService.name);
  private readonly isDev = process.env.NODE_ENV !== 'production';
  private ollamaHost = '';
  private ollamaModel = '';
  private vertexModel: GenerativeModel | null = null;

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    if (this.isDev) {
      const ollama = this.config.get('ollama', { infer: true });
      this.ollamaHost = ollama.host.replace(/\/$/, '');
      this.ollamaModel = ollama.model;
      this.logger.log(
        `LLM: Ollama @ ${this.ollamaHost} (model=${this.ollamaModel})`,
      );
    } else {
      const projectId = this.config.get('gcp.projectId', { infer: true });
      const location = this.config.get('gcp.region', { infer: true });
      const vertex = new VertexAI({ project: projectId, location });
      // Pro: richer reasoning needed for nuanced bias analysis
      this.vertexModel = vertex.getGenerativeModel({
        model: 'gemini-1.5-pro',
        generationConfig: { responseMimeType: 'application/json' },
      });
      this.logger.log(
        `LLM: Vertex AI (project=${projectId}, location=${location})`,
      );
    }
  }

  async generate(prompt: string): Promise<string> {
    if (this.isDev) {
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
        throw new Error(
          `Ollama request failed: ${res.status} ${res.statusText}`,
        );
      }
      const data = (await res.json()) as { response: string };
      return data.response;
    }

    const result = await this.vertexModel!.generateContent(prompt);
    return result.response.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  }
}
