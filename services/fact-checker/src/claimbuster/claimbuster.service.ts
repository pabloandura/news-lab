import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { AppConfig } from '../config/configuration.js';

/**
 * ClaimBuster API integration (optional).
 *
 * ClaimBuster scores individual sentences for "check-worthiness" (0–1).
 * A high score means the sentence makes a specific, verifiable factual claim.
 *
 * API docs: https://idir.uta.edu/claimbuster/api/
 * Register for a free key: https://idir.uta.edu/claimbuster/
 */

const CHECK_WORTHY_THRESHOLD = 0.5;

export interface ClaimScore {
  text: string;
  score: number;
  isCheckWorthy: boolean;
}

@Injectable()
export class ClaimBusterService {
  private readonly logger = new Logger(ClaimBusterService.name);
  private readonly apiKey: string | undefined;
  private readonly apiUrl: string;

  constructor(private readonly config: ConfigService<AppConfig, true>) {
    this.apiKey = this.config.get('claimBuster.apiKey', { infer: true });
    this.apiUrl = this.config.get('claimBuster.apiUrl', { infer: true });
    if (this.apiKey) {
      this.logger.log('ClaimBuster integration enabled');
    } else {
      this.logger.warn('CLAIMBUSTER_API_KEY not set — skipping ClaimBuster scoring, Gemini-only pipeline active');
    }
  }

  get isEnabled(): boolean {
    return !!this.apiKey;
  }

  /**
   * Score a single claim for check-worthiness.
   * Returns null if ClaimBuster is not configured.
   */
  async scoreClaim(claimText: string): Promise<ClaimScore | null> {
    if (!this.apiKey) return null;

    try {
      const response = await axios.post<{ value: { text: string; score: number } }>(
        this.apiUrl,
        { input_claim: claimText },
        {
          headers: { 'x-api-key': this.apiKey },
          timeout: 8_000,
        },
      );

      const score = response.data.value.score;
      return {
        text: claimText,
        score,
        isCheckWorthy: score >= CHECK_WORTHY_THRESHOLD,
      };
    } catch (err) {
      this.logger.warn(`ClaimBuster request failed for claim "${claimText.slice(0, 60)}...": ${err}`);
      return null;
    }
  }

  /**
   * Score multiple claims concurrently.
   * Falls back gracefully — failed individual scores are treated as check-worthy
   * so Gemini still evaluates them rather than silently dropping them.
   */
  async scoreClaims(claims: string[]): Promise<ClaimScore[]> {
    if (!this.apiKey) {
      return claims.map((text) => ({ text, score: 1.0, isCheckWorthy: true }));
    }

    const results = await Promise.all(claims.map((c) => this.scoreClaim(c)));
    return results.map((r, i) =>
      r ?? { text: claims[i], score: 1.0, isCheckWorthy: true },
    );
  }
}
