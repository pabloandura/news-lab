import { Test, TestingModule } from '@nestjs/testing';
import { PolarizeService } from './polarize.service.js';
import { LLM_SERVICE } from '../llm/llm.port.js';
import { FirebaseService } from '../firebase/firebase.service.js';

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

// ── Tests ──────────────────────────────────────────────────────────────────

describe('PolarizeService', () => {
  let service: PolarizeService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PolarizeService,
        { provide: LLM_SERVICE, useValue: mockLlmService },
        { provide: FirebaseService, useValue: mockFirebaseService },
      ],
    }).compile();

    service = module.get<PolarizeService>(PolarizeService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('triggerAsync', () => {
    it('writes biasReport to Firestore with correct scores', async () => {
      mockGenerate.mockResolvedValueOnce(
        JSON.stringify({
          politicalLean: 0.6,
          emotionalLanguageScore: 0.75,
          framingNotes: ['loaded adjectives', 'appeal to fear'],
        }),
      );

      service.triggerAsync({ articleId: 'art-1', text: 'A'.repeat(100) });
      await new Promise((r) => setTimeout(r, 50));

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          biasReport: expect.objectContaining({
            politicalLean: 0.6,
            emotionalLanguageScore: 0.75,
            framingNotes: ['loaded adjectives', 'appeal to fear'],
          }),
        }),
        { merge: true },
      );
    });

    it('clamps politicalLean to [-1, 1]', async () => {
      mockGenerate.mockResolvedValueOnce(
        JSON.stringify({ politicalLean: 2.5, emotionalLanguageScore: 0.5, framingNotes: [] }),
      );

      service.triggerAsync({ articleId: 'art-2', text: 'A'.repeat(100) });
      await new Promise((r) => setTimeout(r, 50));

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          biasReport: expect.objectContaining({ politicalLean: 1 }),
        }),
        { merge: true },
      );
    });

    it('clamps emotionalLanguageScore to [0, 1]', async () => {
      mockGenerate.mockResolvedValueOnce(
        JSON.stringify({ politicalLean: 0, emotionalLanguageScore: -0.5, framingNotes: [] }),
      );

      service.triggerAsync({ articleId: 'art-3', text: 'A'.repeat(100) });
      await new Promise((r) => setTimeout(r, 50));

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          biasReport: expect.objectContaining({ emotionalLanguageScore: 0 }),
        }),
        { merge: true },
      );
    });

    it('handles malformed LLM response gracefully', async () => {
      mockGenerate.mockResolvedValueOnce('not json');

      service.triggerAsync({ articleId: 'art-4', text: 'A'.repeat(100) });
      await new Promise((r) => setTimeout(r, 50));

      // Falls back to neutral values
      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          biasReport: expect.objectContaining({
            politicalLean: 0,
            emotionalLanguageScore: 0,
            framingNotes: [],
          }),
        }),
        { merge: true },
      );
    });

    it('does not throw when Firestore write fails', async () => {
      mockGenerate.mockResolvedValueOnce(
        JSON.stringify({ politicalLean: 0, emotionalLanguageScore: 0, framingNotes: [] }),
      );
      mockSet.mockRejectedValueOnce(new Error('Firestore unavailable'));

      expect(() =>
        service.triggerAsync({ articleId: 'art-5', text: 'A'.repeat(100) }),
      ).not.toThrow();

      await new Promise((r) => setTimeout(r, 50));
    });
  });
});
