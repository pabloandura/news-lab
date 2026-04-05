// ── fact-checker API contract ──────────────────────────────────────────────

export interface FactCheckRequest {
  articleId: string;
  text: string;
}

export interface FactCheckResponse {
  status: 'processing';
  articleId: string;
}

export interface BotCheckResult {
  flaggedSentencesPercent: number; // 0.0–1.0
  confidenceScore: number;         // 0.0–1.0
  checkedAt: string;               // ISO 8601 timestamp
}
