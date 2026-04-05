// ── sensemaker API contract ────────────────────────────────────────────────

export interface SimilarRequest {
  articleId?: string; // if article is already indexed
  text?: string;      // OR raw text for user-authored articles
}

export interface SimilarArticle {
  title: string;
  source: string;
  url: string;
  publishedAt: string;
  similarityScore: number;
  snippet: string;
}

export interface SimilarResponse {
  results: SimilarArticle[];
}

// Internal — used by the ingestion pipeline, not the Flutter client
export interface IngestResponse {
  ingested: number;
  deduplicated: number;
  timestamp: string;
}
