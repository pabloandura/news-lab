import { Injectable, Logger } from '@nestjs/common';
import { LlmService } from '../llm/llm.service.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { ClaimBusterService } from '../claimbuster/claimbuster.service.js';
import { FactCheckRequestDto } from './dto/fact-check-request.dto.js';
import { BotCheckResult } from '@news-lab/types';
import { FieldValue } from 'firebase-admin/firestore';

// ── Gemini response shapes ─────────────────────────────────────────────────

interface ClaimsList {
  claims: string[];
}

type ClaimVerdict = 'supported' | 'contested' | 'false' | 'unverifiable';

interface ClaimEvaluation {
  verdict: ClaimVerdict;
  confidence: number; // 0.0–1.0
  reasoning: string;
}

// ── Prompts ────────────────────────────────────────────────────────────────

const EXTRACTION_PROMPT = `You are a fact-checking assistant.
Extract all discrete, independently verifiable factual claims from the article below.
Ignore opinions, predictions, and rhetorical statements — only include concrete facts that can be checked.

Return ONLY valid JSON matching this schema:
{ "claims": ["claim 1", "claim 2", ...] }

If the article contains no verifiable claims, return: { "claims": [] }

Article:
`;

const EVALUATION_PROMPT = `You are a fact-checking expert.
Evaluate the following factual claim for accuracy based on your knowledge.

Claim: "{CLAIM}"

Return ONLY valid JSON matching this schema:
{
  "verdict": "supported" | "contested" | "false" | "unverifiable",
  "confidence": <number between 0.0 and 1.0>,
  "reasoning": "<one concise sentence>"
}
`;

@Injectable()
export class FactCheckService {
  private readonly logger = new Logger(FactCheckService.name);
  private readonly FACT_CHECKS_COLLECTION = 'fact_checks';

  constructor(
    private readonly llm: LlmService,
    private readonly firebase: FirebaseService,
    private readonly claimBuster: ClaimBusterService,
  ) {}

  /**
   * Trigger fact-check pipeline asynchronously.
   * Returns immediately after acknowledging the request;
   * writes the result to Firestore when the pipeline completes.
   */
  triggerAsync(dto: FactCheckRequestDto): void {
    this.runPipeline(dto).catch((err) =>
      this.logger.error(`Pipeline failed for article ${dto.articleId}: ${err}`),
    );
  }

  // ── Pipeline ─────────────────────────────────────────────────────────────

  private async runPipeline(dto: FactCheckRequestDto): Promise<void> {
    this.logger.log(`Starting pipeline for article ${dto.articleId}`);

    const claims = await this.extractClaims(dto.text);
    this.logger.debug(`Extracted ${claims.length} claims from article ${dto.articleId}`);

    if (claims.length === 0) {
      await this.writeResult(dto.articleId, {
        flaggedSentencesPercent: 0,
        confidenceScore: 1.0,
        checkedAt: new Date().toISOString(),
      });
      return;
    }

    // Step 2: Score claims via ClaimBuster (or pass all through if not configured)
    const scored = await this.claimBuster.scoreClaims(claims);
    const checkWorthy = scored.filter((s) => s.isCheckWorthy);

    this.logger.debug(
      `${checkWorthy.length}/${claims.length} claims are check-worthy (ClaimBuster enabled=${this.claimBuster.isEnabled})`,
    );

    if (checkWorthy.length === 0) {
      await this.writeResult(dto.articleId, {
        flaggedSentencesPercent: 0,
        confidenceScore: 0.9,
        checkedAt: new Date().toISOString(),
      });
      return;
    }

    // Step 3: Evaluate each check-worthy claim with Gemini
    const evaluations = await this.evaluateClaims(checkWorthy.map((c) => c.text));

    // Step 4: Compute scores
    const flagged = evaluations.filter(
      (e) => e.verdict === 'contested' || e.verdict === 'false',
    );
    const flaggedSentencesPercent = flagged.length / claims.length;
    const confidenceScore =
      evaluations.reduce((sum, e) => sum + e.confidence, 0) / evaluations.length;

    this.logger.log(
      `Article ${dto.articleId}: ${flagged.length} flagged / ${claims.length} total, confidence=${confidenceScore.toFixed(2)}`,
    );

    await this.writeResult(dto.articleId, {
      flaggedSentencesPercent: parseFloat(flaggedSentencesPercent.toFixed(4)),
      confidenceScore: parseFloat(confidenceScore.toFixed(4)),
      checkedAt: new Date().toISOString(),
    });
  }

  // ── Gemini: claim extraction ──────────────────────────────────────────────

  private async extractClaims(text: string): Promise<string[]> {
    const raw = await this.llm.generate(EXTRACTION_PROMPT + text);

    try {
      const parsed = JSON.parse(raw) as ClaimsList;
      return Array.isArray(parsed.claims) ? parsed.claims : [];
    } catch {
      this.logger.warn('Failed to parse Gemini claim extraction response');
      return [];
    }
  }

  // ── Gemini: per-claim evaluation ─────────────────────────────────────────

  private async evaluateClaims(claims: string[]): Promise<ClaimEvaluation[]> {
    const results = await Promise.all(claims.map((c) => this.evaluateSingleClaim(c)));
    return results;
  }

  private async evaluateSingleClaim(claim: string): Promise<ClaimEvaluation> {
    const prompt = EVALUATION_PROMPT.replace('{CLAIM}', claim);

    try {
      const raw = await this.llm.generate(prompt);
      const parsed = JSON.parse(raw) as ClaimEvaluation;

      return {
        verdict: this.sanitiseVerdict(parsed.verdict),
        confidence: Math.min(1, Math.max(0, Number(parsed.confidence) || 0.5)),
        reasoning: parsed.reasoning ?? '',
      };
    } catch {
      this.logger.warn(`Could not evaluate claim: "${claim.slice(0, 60)}..."`);
      return { verdict: 'unverifiable', confidence: 0.5, reasoning: 'Evaluation failed' };
    }
  }

  private sanitiseVerdict(raw: unknown): ClaimVerdict {
    const allowed: ClaimVerdict[] = ['supported', 'contested', 'false', 'unverifiable'];
    return allowed.includes(raw as ClaimVerdict) ? (raw as ClaimVerdict) : 'unverifiable';
  }

  // ── Firestore write ───────────────────────────────────────────────────────

  private async writeResult(articleId: string, result: BotCheckResult): Promise<void> {
    await this.firebase.db
      .collection(this.FACT_CHECKS_COLLECTION)
      .doc(articleId)
      .set(
        {
          botCheck: {
            ...result,
            checkedAt: FieldValue.serverTimestamp(),
          },
        },
        { merge: true },
      );

    this.logger.log(`Wrote botCheck result to fact_checks/${articleId}`);
  }
}
