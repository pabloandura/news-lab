import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VertexAI } from '@google-cloud/vertexai';
import { AppConfig } from '../config/configuration.js';

@Injectable()
export class EmbeddingService implements OnApplicationBootstrap {
  private readonly logger = new Logger(EmbeddingService.name);
  private readonly isDev = process.env.NODE_ENV !== 'production';
  private ollamaHost = '';
  private ollamaModel = '';
  private vertexAI: VertexAI | null = null;
  private vertexProject = '';
  private vertexLocation = '';

  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  onApplicationBootstrap(): void {
    if (this.isDev) {
      const ollama = this.config.get('ollama', { infer: true });
      this.ollamaHost = ollama.host.replace(/\/$/, '');
      this.ollamaModel = ollama.model;
      this.logger.log(`Embeddings: Ollama @ ${this.ollamaHost} (model=${this.ollamaModel})`);
    } else {
      this.vertexProject = this.config.get('gcp.projectId', { infer: true });
      this.vertexLocation = this.config.get('gcp.region', { infer: true });
      this.vertexAI = new VertexAI({ project: this.vertexProject, location: this.vertexLocation });
      this.logger.log(`Embeddings: Vertex AI text-embedding-004 (project=${this.vertexProject})`);
    }
  }

  async embed(text: string): Promise<number[]> {
    if (this.isDev) {
      return this.embedOllama(text);
    }
    return this.embedVertex(text);
  }

  // ── Ollama (local dev) ─────────────────────────────────────────────────────

  private async embedOllama(text: string): Promise<number[]> {
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

  // ── Vertex AI (production) ─────────────────────────────────────────────────

  private async embedVertex(text: string): Promise<number[]> {
    const endpoint = `https://${this.vertexLocation}-aiplatform.googleapis.com/v1/projects/${this.vertexProject}/locations/${this.vertexLocation}/publishers/google/models/text-embedding-004:predict`;

    const { GoogleAuth } = await import('google-auth-library');
    const auth = new GoogleAuth({ scopes: 'https://www.googleapis.com/auth/cloud-platform' });
    const client = await auth.getClient();
    const token = await client.getAccessToken();

    const res = await fetch(endpoint, {
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
