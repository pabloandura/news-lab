import { Injectable, Logger, Inject } from '@nestjs/common';
import { LLM_SERVICE } from '../llm/llm.port.js';
import type { ILlmService } from '../llm/llm.port.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { PolarizeRequestDto } from './dto/polarize-request.dto.js';
import { BiasReport } from '@news-lab/types';
import { FieldValue } from 'firebase-admin/firestore';

// ── Gemini response shape ─────────────────────────────────────────────────

interface BiasAnalysis {
  politicalLean: number;
  emotionalLanguageScore: number;
  framingNotes: string[];
}

// ── Prompt ────────────────────────────────────────────────────────────────

const BIAS_PROMPT = `You are a media bias analyst. Analyze the FRAMING AND AUTHORIAL PERSPECTIVE of the following article — not the topic itself.

CRITICAL: Score the direction of the author's stance, not what the article is about.
- Anti-union, anti-regulation, pro-gun, anti-immigration, anti-government framing = RIGHT-leaning (POSITIVE score)
- Pro-union, pro-regulation, anti-gun, pro-immigration, pro-government framing = LEFT-leaning (NEGATIVE score)
- Neutral/balanced reporting = near 0.0

Return ONLY valid JSON matching this exact schema:
{
  "politicalLean": <number from -1.0 (strongly left) to +1.0 (strongly right), 0.0 is neutral>,
  "emotionalLanguageScore": <number from 0.0 (purely factual) to 1.0 (highly emotional/charged)>,
  "framingNotes": ["<specific technique observed>", ...]
}

Examples of framing notes: "passive voice to obscure agency", "loaded adjectives", "selective sourcing", "appeal to fear", "us-vs-them framing", "positive spin on statistics".

Article:
`;

@Injectable()
export class PolarizeService {
  private readonly logger = new Logger(PolarizeService.name);
  private readonly ARTICLES_COLLECTION = 'articles';

  constructor(
    @Inject(LLM_SERVICE) private readonly llm: ILlmService,
    private readonly firebase: FirebaseService,
  ) {}

  /**
   * Trigger bias analysis asynchronously.
   * Returns immediately; writes result to Firestore when complete.
   */
  triggerAsync(dto: PolarizeRequestDto): void {
    this.runPipeline(dto).catch((err) =>
      this.logger.error(`Pipeline failed for article ${dto.articleId}: ${err}`),
    );
  }

  // ── Pipeline ─────────────────────────────────────────────────────────────

  private async runPipeline(dto: PolarizeRequestDto): Promise<void> {
    this.logger.log(`Starting bias analysis for article ${dto.articleId}`);

    const analysis = await this.analyzeBias(dto.text);

    const report: BiasReport = {
      politicalLean: this.clamp(analysis.politicalLean, -1, 1),
      emotionalLanguageScore: this.clamp(analysis.emotionalLanguageScore, 0, 1),
      framingNotes: Array.isArray(analysis.framingNotes) ? analysis.framingNotes : [],
      analyzedAt: new Date().toISOString(),
    };

    this.logger.log(
      `Article ${dto.articleId}: politicalLean=${report.politicalLean.toFixed(2)}, emotionalScore=${report.emotionalLanguageScore.toFixed(2)}, notes=${report.framingNotes.length}`,
    );

    await this.writeResult(dto.articleId, report);
  }

  // ── Gemini: bias analysis ─────────────────────────────────────────────────

  private async analyzeBias(text: string): Promise<BiasAnalysis> {
    const fallback: BiasAnalysis = {
      politicalLean: 0,
      emotionalLanguageScore: 0,
      framingNotes: [],
    };

    try {
      const raw = await this.llm.generate(BIAS_PROMPT + text);
      this.logger.debug(`Raw LLM response: ${raw}`);
      const parsed = JSON.parse(raw) as BiasAnalysis;

      return {
        politicalLean: parsed.politicalLean != null ? Number(parsed.politicalLean) : 0,
        emotionalLanguageScore: parsed.emotionalLanguageScore != null ? Number(parsed.emotionalLanguageScore) : 0,
        framingNotes: Array.isArray(parsed.framingNotes) ? parsed.framingNotes : [],
      };
    } catch (err) {
      this.logger.warn(`Failed to parse LLM bias analysis response: ${err}`);
      return fallback;
    }
  }

  // ── Firestore write ───────────────────────────────────────────────────────

  private async writeResult(articleId: string, report: BiasReport): Promise<void> {
    await this.firebase.db
      .collection(this.ARTICLES_COLLECTION)
      .doc(articleId)
      .set(
        {
          biasReport: {
            ...report,
            analyzedAt: FieldValue.serverTimestamp(),
          },
        },
        { merge: true },
      );

    this.logger.log(`Wrote biasReport to articles/${articleId}`);
  }

  private clamp(value: number, min: number, max: number): number {
    return parseFloat(Math.min(max, Math.max(min, value)).toFixed(4));
  }
}
