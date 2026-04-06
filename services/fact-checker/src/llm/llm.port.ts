export const LLM_SERVICE = 'LLM_SERVICE';

export interface ILlmService {
  generate(prompt: string): Promise<string>;
}
