export interface AppConfig {
  port: number;
  gcp: {
    projectId: string;
    region: string;
  };
  claimBuster: {
    apiKey: string | undefined;
  };
}

export default (): AppConfig => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  gcp: {
    projectId: process.env.GCP_PROJECT_ID ?? 'news-lab-2ba2d',
    region: process.env.GCP_REGION ?? 'us-central1',
  },
  claimBuster: {
    apiKey: process.env.CLAIMBUSTER_API_KEY,
  },
});
