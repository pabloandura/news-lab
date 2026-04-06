import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { EmbeddingService } from '../embedding/embedding.service.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { SimilarRequestDto } from './dto/similar-request.dto.js';
import type { SimilarArticle, SimilarResponse } from '@news-lab/types';

const COLLECTION = 'sensemaker_articles';
const TOP_N = 15;

interface StoredArticle {
  title: string;
  source: string;
  url: string;
  publishedAt: string;
  snippet: string;
}

@Injectable()
export class SimilarService {
  private readonly logger = new Logger(SimilarService.name);

  constructor(
    private readonly embedding: EmbeddingService,
    private readonly firebase: FirebaseService,
  ) {}

  async findSimilar(dto: SimilarRequestDto): Promise<SimilarResponse> {
    const queryText = await this.resolveQueryText(dto);
    const queryVector = await this.embedding.embed(queryText);

    const collection = this.firebase.db.collection(COLLECTION);

    const results = await collection
      .findNearest('embedding', queryVector as unknown as number[], {
        limit: TOP_N,
        distanceMeasure: 'COSINE',
      })
      .get();

    const articles: SimilarArticle[] = results.docs.map((doc, index) => {
      const data = doc.data() as StoredArticle;
      // Firestore returns documents ordered by similarity; derive a score from rank
      const similarityScore = Math.max(0, 1 - index * (1 / TOP_N));
      return {
        title: data.title,
        source: data.source,
        url: data.url,
        publishedAt: data.publishedAt,
        snippet: data.snippet,
        similarityScore: parseFloat(similarityScore.toFixed(3)),
      };
    });

    this.logger.log(`Found ${articles.length} similar articles for query`);
    return { results: articles };
  }

  private async resolveQueryText(dto: SimilarRequestDto): Promise<string> {
    if (dto.text) return dto.text;

    if (dto.articleId) {
      // Try to look up the article in sensemaker_articles first
      const snap = await this.firebase.db
        .collection(COLLECTION)
        .where('articleId', '==', dto.articleId)
        .limit(1)
        .get();

      if (!snap.empty) {
        const data = snap.docs[0].data() as StoredArticle;
        return `${data.title} ${data.snippet}`;
      }

      // Fall back to the articles collection (user-authored articles)
      const articleSnap = await this.firebase.db
        .collection('articles')
        .doc(dto.articleId)
        .get();

      if (articleSnap.exists) {
        const data = articleSnap.data() as { title?: string; description?: string; content?: string };
        return `${data.title ?? ''} ${data.description ?? ''} ${data.content ?? ''}`.trim();
      }
    }

    throw new BadRequestException('Provide either articleId (of a known article) or text');
  }
}
