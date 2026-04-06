import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VertexAI, GenerativeModel } from '@google-cloud/vertexai';
import { AppConfig } from '../config/configuration.js';
import { ILlmService } from './llm.port.js';

@Injectable()
export class VertexLlmService implements ILlmService, OnApplicationBootstrap {
  private readonly logger = new Logger(VertexLlmService.name);
  private vertexModel: GenerativeModel | null = null;

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    const projectId = this.config.get('gcp.projectId', { infer: true });
    const location = this.config.get('gcp.region', { infer: true });
    const vertex = new VertexAI({ project: projectId, location });
    // Pro: richer reasoning needed for nuanced bias analysis
    this.vertexModel = vertex.getGenerativeModel({
      model: 'gemini-1.5-pro',
      generationConfig: { responseMimeType: 'application/json' },
    });
    this.logger.log(`LLM: Vertex AI (project=${projectId}, location=${location})`);
  }

  async generate(prompt: string): Promise<string> {
    const result = await this.vertexModel!.generateContent(prompt);
    return result.response.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  }
}
