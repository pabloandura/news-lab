export const EMBEDDING_SERVICE = 'EMBEDDING_SERVICE';

export interface IEmbeddingService {
  embed(text: string): Promise<number[]>;
}
