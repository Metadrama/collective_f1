/// A service that provides API keys for various services
class ApiKeyService {
  /// The DeepSeek API key provided by the developer
  static String getDeepseekApiKey() {
    // In a real production app, you would want to use obfuscation techniques 
    // or a more secure approach to protect this key
    const apiKey = 'sk-f2f2cf5a3b4d4419a17c94d602932eaf';
    return apiKey;
  }

  /// Google Cloud Vision API key
  ///
  /// IMPORTANT: Do not hardcode real secrets in production. Prefer
  /// runtime injection (dart-define), platform keychain, or remote config.
  /// This placeholder enables wiring; set your key during development.
  static String getGoogleVisionApiKey() {
    const apiKey = 'AIzaSyB3Fal2zYqp5OudwpvkgOA8BWSc06-vUFI';
    return apiKey;
  }
}
