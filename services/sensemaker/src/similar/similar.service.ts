import { Injectable, Logger, BadRequestException, Inject } from '@nestjs/common';
import { EMBEDDING_SERVICE } from '../embedding/embedding.port.js';
import type { IEmbeddingService } from '../embedding/embedding.port.js';
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
    @Inject(EMBEDDING_SERVICE) private readonly embedding: IEmbeddingService,
    private readonly firebase: FirebaseService,
  ) {}

  async findSimilar(dto: SimilarRequestDto): Promise<SimilarResponse> {
    const queryText = await this.resolveQueryText(dto);
    const queryVector = await this.embedding.embed(queryText);

    const collection = this.firebase.db.collection(COLLECTION);

    const results = await collection
      .findNearest({
        vectorField: 'embedding',
        queryVector: queryVector as unknown as number[],
        limit: TOP_N,
        distanceMeasure: 'COSINE',
        distanceResultField: 'distanceTo',
      })
      .get();

    const articles: SimilarArticle[] = results.docs.map((doc) => {
      const data = doc.data() as StoredArticle;
      const cosineDistance = doc.get('distanceTo') as number;
      const similarityScore = parseFloat(Math.max(0, 1 - cosineDistance).toFixed(3));
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
      // Look up the article in the articles collection (user-authored articles)
      const articleSnap = await this.firebase.db
        .collection('articles')
        .doc(dto.articleId)
        .get();

      if (articleSnap.exists) {
        const data = articleSnap.data() as { title?: string; description?: string; content?: string };
        return `${data.title ?? ''} ${data.description ?? ''} ${data.content ?? ''}`.trim();
      }

      // Fall back to sensemaker_articles (NewsAPI articles use md5(url) as doc ID)
      const sensemakerSnap = await this.firebase.db
        .collection(COLLECTION)
        .doc(dto.articleId)
        .get();

      if (sensemakerSnap.exists) {
        const data = sensemakerSnap.data() as { title?: string; snippet?: string };
        return `${data.title ?? ''} ${data.snippet ?? ''}`.trim();
      }
    }

    throw new BadRequestException('Provide either articleId (of a known article) or text');
  }
}
