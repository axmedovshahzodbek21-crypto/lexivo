// App-wide configuration constants.

/// Base URL of the Lexivo web app, which also hosts the API routes the
/// Flutter app calls (`/api/tts`, `/api/digest`), the bundled-content CDN
/// (`/data/*.json`), and the password-reset page (`/update-password`).
///
/// Was previously hardcoded as `lexivo-web-six.vercel.app` in five different
/// places; the canonical alias is now `lexivo-web-nu.vercel.app` (see
/// Settings › Website). Both aliases currently resolve, but only this one is
/// guaranteed to track the production deployment.
const String kLexivoWebBase = 'https://lexivo-web-nu.vercel.app';
