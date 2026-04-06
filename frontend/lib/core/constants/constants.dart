const String newsAPIBaseURL = 'https://newsapi.org/v2';

// API Gateway URL — single entry point for all microservices.
// Get the hostname after running: just gateway-url
// Override at build time: --dart-define=MICROSERVICES_BASE_URL=http://localhost:3000
const String microservicesBaseUrl = String.fromEnvironment(
  'MICROSERVICES_BASE_URL',
  defaultValue: 'https://news-lab-gateway-<hash>.uc.gateway.dev',
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
