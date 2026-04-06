import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleAuth } from 'google-auth-library';
import { AppConfig } from '../config/configuration.js';
import { IEmbeddingService } from './embedding.port.js';

type AuthClient = Awaited<ReturnType<GoogleAuth['getClient']>>;

@Injectable()
export class VertexEmbeddingService implements IEmbeddingService, OnApplicationBootstrap {
  private readonly logger = new Logger(VertexEmbeddingService.name);
  private endpoint = '';
  private authClient: AuthClient | null = null;

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  async onApplicationBootstrap(): Promise<void> {
    const project = this.config.get('gcp.projectId', { infer: true });
    const location = this.config.get('gcp.region', { infer: true });
    this.endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/text-embedding-004:predict`;
    const auth = new GoogleAuth({ scopes: 'https://www.googleapis.com/auth/cloud-platform' });
    this.authClient = await auth.getClient();
    this.logger.log(`Embeddings: Vertex AI text-embedding-004 (project=${project})`);
  }

  async embed(text: string): Promise<number[]> {
    const token = await this.authClient!.getAccessToken();
    const res = await fetch(this.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.token}`,
      },
      body: JSON.stringify({ instances: [{ content: text }] }),
    });
    if (!res.ok) {
      throw new Error(`Vertex AI embeddings failed: ${res.status} ${res.statusText}`);
    }
    const data = (await res.json()) as { predictions: [{ embeddings: { values: number[] } }] };
    return data.predictions[0].embeddings.values;
  }
}
