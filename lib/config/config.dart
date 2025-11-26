import 'env_config.dart';

class Config {
  // Unified ML API configuration
  // All ML services (skill classifier, code corruptor, code similarity) run on one server
  // Configure the base URL in lib/env_config.dart
  
  static String get _baseUrl => EnvConfig.mlApiBaseUrl;
  
  // All services use the same base URL with different endpoints
  static String get similarityApiBase => _baseUrl;  // Uses /score
  static String get corruptorApiBase => _baseUrl;    // Uses /get_corrupted_snippet
  static String get skillApiBase => _baseUrl;        // Uses /predict_level
  static String get ollamaApiBase => EnvConfig.ollamaApiBaseUrl;  // Ollama LLM service
  
  // Backward compatibility
  static String get apiBase => _baseUrl;
}
