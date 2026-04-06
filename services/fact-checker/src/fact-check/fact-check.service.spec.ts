import { Test, TestingModule } from '@nestjs/testing';
import { FactCheckService } from './fact-check.service.js';
import { LLM_SERVICE } from '../llm/llm.port.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { ClaimBusterService } from '../claimbuster/claimbuster.service.js';

// ── Mocks ──────────────────────────────────────────────────────────────────

const mockGenerate = jest.fn();
const mockLlmService = { generate: mockGenerate };

const mockSet = jest.fn().mockResolvedValue(undefined);
const mockFirebaseService = {
  db: {
    collection: jest.fn().mockReturnValue({
      doc: jest.fn().mockReturnValue({ set: mockSet }),
    }),
  },
};

const mockClaimBusterService = {
  isEnabled: false,
  scoreClaims: jest.fn().mockImplementation((claims: string[]) =>
    Promise.resolve(claims.map((text) => ({ text, score: 1.0, isCheckWorthy: true }))),
  ),
};

// ── Tests ──────────────────────────────────────────────────────────────────

describe('FactCheckService', () => {
  let service: FactCheckService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FactCheckService,
        { provide: LLM_SERVICE, useValue: mockLlmService },
        { provide: FirebaseService, useValue: mockFirebaseService },
        { provide: ClaimBusterService, useValue: mockClaimBusterService },
      ],
    }).compile();

    service = module.get<FactCheckService>(FactCheckService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('triggerAsync', () => {
    it('writes botCheck to Firestore when claims are extracted and evaluated', async () => {
      // First call: claim extraction
      mockGenerate
        .mockResolvedValueOnce(
          JSON.stringify({ claims: ['The unemployment rate fell to 3.5%.', 'GDP grew 2% last quarter.'] }),
        )
        // Second + third calls: per-claim evaluation
        .mockResolvedValueOnce(JSON.stringify({ verdict: 'supported', confidence: 0.9, reasoning: 'Matches BLS data' }))
        .mockResolvedValueOnce(JSON.stringify({ verdict: 'contested', confidence: 0.7, reasoning: 'Disputed by IMF' }));

      service.triggerAsync({ articleId: 'art-1', text: 'A'.repeat(100) });

      // Wait for async pipeline
      await new Promise((r) => setTimeout(r, 50));

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          botCheck: expect.objectContaining({
            flaggedSentencesPercent: 0.5,   // 1 contested / 2 total
            confidenceScore: 0.8,           // (0.9 + 0.7) / 2
          }),
        }),
        { merge: true },
      );
    });

    it('writes zero flagged when no claims are extracted', async () => {
      mockGenerate.mockResolvedValueOnce(JSON.stringify({ claims: [] }));

      service.triggerAsync({ articleId: 'art-2', text: 'A'.repeat(100) });
      await new Promise((r) => setTimeout(r, 50));

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          botCheck: expect.objectContaining({
            flaggedSentencesPercent: 0,
            confidenceScore: 1.0,
          }),
        }),
        { merge: true },
      );
    });

    it('handles malformed LLM extraction response gracefully', async () => {
      mockGenerate.mockResolvedValueOnce('not json');

      service.triggerAsync({ articleId: 'art-3', text: 'A'.repeat(100) });
      await new Promise((r) => setTimeout(r, 50));

      // Falls back to no claims → writes 0 flagged
      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          botCheck: expect.objectContaining({ flaggedSentencesPercent: 0 }),
        }),
        { merge: true },
      );
    });

    it('does not throw when Firestore write fails', async () => {
      mockGenerate.mockResolvedValueOnce(JSON.stringify({ claims: [] }));
      mockSet.mockRejectedValueOnce(new Error('Firestore unavailable'));

      // Should not throw
      expect(() =>
        service.triggerAsync({ articleId: 'art-4', text: 'A'.repeat(100) }),
      ).not.toThrow();

      await new Promise((r) => setTimeout(r, 50));
    });
  });
});
