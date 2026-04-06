import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VertexAI, GenerativeModel } from '@google-cloud/vertexai';
import { AppConfig } from '../config/configuration.js';

@Injectable()
export class VertexService implements OnApplicationBootstrap {
  private readonly logger = new Logger(VertexService.name);
  private _claimExtractor!: GenerativeModel;
  private _claimEvaluator!: GenerativeModel;

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    const projectId = this.config.get('gcp.projectId', { infer: true });
    const location = this.config.get('gcp.region', { infer: true });

    const vertex = new VertexAI({ project: projectId, location });

    // Flash: fast structured extraction of claims list
    this._claimExtractor = vertex.getGenerativeModel({
      model: 'gemini-1.5-flash',
      generationConfig: { responseMimeType: 'application/json' },
    });

    // Flash is also sufficient for per-claim plausibility evaluation
    this._claimEvaluator = vertex.getGenerativeModel({
      model: 'gemini-1.5-flash',
      generationConfig: { responseMimeType: 'application/json' },
    });

    this.logger.log(`Vertex AI initialised (project=${projectId}, location=${location})`);
  }

  get claimExtractor(): GenerativeModel {
    return this._claimExtractor;
  }

  get claimEvaluator(): GenerativeModel {
    return this._claimEvaluator;
  }
}
