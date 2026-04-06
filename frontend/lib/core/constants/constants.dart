const String newsAPIBaseURL = 'https://newsapi.org/v2';

// Microservices API Gateway URL.
// Phase 1: points directly to the fact-checker Cloud Run service.
// Phase 2: update to the API Gateway URL once established.
// Override at build time: --dart-define=MICROSERVICES_BASE_URL=http://localhost:3000
const String microservicesBaseUrl = String.fromEnvironment(
  'MICROSERVICES_BASE_URL',
  defaultValue: 'https://fact-checker-<hash>-uc.a.run.app',
);
const String newsAPIKey = String.fromEnvironment('NEWS_API_KEY');
const String countryQuery = 'us';
const String categoryQuery = 'general';
const String kDefaultImage =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/480px-No_image_available.svg.png';
const String articlesCollection = 'articles';
const String articlesThumbnailStoragePath = 'media/articles';
const String factChecksCollection = 'fact_checks';
const String votesSubcollection = 'votes';
