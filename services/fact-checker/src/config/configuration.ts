export interface AppConfig {
  nodeEnv: string;
  port: number;
  gcp: {
    projectId: string;
    region: string;
  };
  ollama: {
    host: string;
    model: string;
  };
  claimBuster: {
    apiKey: string | undefined;
    apiUrl: string;
  };
}

export default (): AppConfig => ({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: parseInt(process.env.PORT ?? '3000', 10),
  gcp: {
    projectId: process.env.GCP_PROJECT_ID ?? 'news-lab-2ba2d',
    region: process.env.GCP_REGION ?? 'us-central1',
  },
  ollama: {
    host: process.env.OLLAMA_HOST ?? 'http://localhost:11434',
    model: process.env.OLLAMA_MODEL ?? 'llama3.2',
  },
  claimBuster: {
    apiKey: process.env.CLAIMBUSTER_API_KEY,
    apiUrl: process.env.CLAIMBUSTER_API_URL ?? 'https://idir.uta.edu/api/v1/factcheck/claims/',
  },
});
