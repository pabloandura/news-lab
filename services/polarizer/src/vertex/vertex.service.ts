import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VertexAI, GenerativeModel } from '@google-cloud/vertexai';
import { AppConfig } from '../config/configuration.js';

@Injectable()
export class VertexService implements OnApplicationBootstrap {
  private readonly logger = new Logger(VertexService.name);
  private _biasAnalyzer!: GenerativeModel;

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    const projectId = this.config.get('gcp.projectId', { infer: true });
    const location = this.config.get('gcp.region', { infer: true });

    const vertex = new VertexAI({ project: projectId, location });

    // Pro: richer reasoning needed for nuanced bias analysis
    this._biasAnalyzer = vertex.getGenerativeModel({
      model: 'gemini-1.5-pro',
      generationConfig: { responseMimeType: 'application/json' },
    });

    this.logger.log(`Vertex AI initialised (project=${projectId}, location=${location})`);
  }

  get biasAnalyzer(): GenerativeModel {
    return this._biasAnalyzer;
  }
}
