// ── polarizer API contract ─────────────────────────────────────────────────

export interface PolarizeRequest {
  articleId: string;
  text: string;
}

export interface PolarizeResponse {
  status: 'processing';
  articleId: string;
}

export interface BiasReport {
  politicalLean: number;          // -1.0 (left) to +1.0 (right)
  emotionalLanguageScore: number; // 0.0 (neutral) to 1.0 (highly charged)
  framingNotes: string[];         // e.g. ["passive voice", "loaded adjectives"]
  analyzedAt: string;             // ISO 8601 timestamp
}
