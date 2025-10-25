/// A service that provides API keys for various services
class ApiKeyService {
  /// The DeepSeek API key provided by the developer
  static String getDeepseekApiKey() {
    // In a real production app, you would want to use obfuscation techniques 
    // or a more secure approach to protect this key
    const apiKey = 'sk-f2f2cf5a3b4d4419a17c94d602932eaf';
    return apiKey;
  }
}
