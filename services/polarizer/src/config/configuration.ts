export interface AppConfig {
  port: number;
  gcp: {
    projectId: string;
    region: string;
  };
  ollama: {
    host: string;
    model: string;
  };
}

export default (): AppConfig => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  gcp: {
    projectId: process.env.GCP_PROJECT_ID ?? 'news-lab-2ba2d',
    region: process.env.GCP_REGION ?? 'us-central1',
  },
  ollama: {
    host: process.env.OLLAMA_HOST ?? 'http://localhost:11434',
    model: process.env.OLLAMA_MODEL ?? 'llama3.2',
  },
});
