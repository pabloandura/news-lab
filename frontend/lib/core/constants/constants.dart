const String newsAPIBaseURL = 'https://newsapi.org/v2';

// Service URLs — in production, both are overridden to the API Gateway URL via:
//   --dart-define=MICROSERVICES_BASE_URL=https://<gateway-host>
// In local dev (no dart-define), each service runs on its own port:
//   just dev polarizer   → http://localhost:3001
//   just dev fact-checker → http://localhost:3002
const String polarizerBaseUrl = String.fromEnvironment(
  'MICROSERVICES_BASE_URL',
  defaultValue: 'http://localhost:3001',
);
const String factCheckerBaseUrl = String.fromEnvironment(
  'MICROSERVICES_BASE_URL',
  defaultValue: 'http://localhost:3002',
);
const String sensemakerBaseUrl = String.fromEnvironment(
  'MICROSERVICES_BASE_URL',
  defaultValue: 'http://localhost:3003',
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
const String articleViewsCollection = 'article_views';
const String dailyViewsSubcollection = 'daily_views';
const String authorDailyViewsCollection = 'author_daily_views';
const String daysSubcollection = 'days';
const String statsCollection = 'stats';
const String biasLandscapeDoc = 'bias_landscape';
