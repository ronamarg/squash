class Config {
  // Unified ML API configuration
  // All ML services (skill classifier, code corruptor, code similarity) run on one server
  // Change these values depending on where your API runs:
  // - Windows/Desktop -> 'http://localhost:5001' or 'http://127.0.0.1:5001'
  // - Android emulator -> 'http://10.0.2.2:5001'
  // - iOS simulator -> 'http://127.0.0.1:5001'
  // - Physical device -> 'http://<your-machine-lan-ip>:5001'
  
  static const String _baseUrl = 'http://localhost:5001';  // Changed for Windows desktop
  
  // All services use the same base URL with different endpoints
  static const String similarityApiBase = _baseUrl;  // Uses /score
  static const String corruptorApiBase = _baseUrl;    // Uses /corrupt
  static const String skillApiBase = _baseUrl;        // Uses /predict_level
  
  // Backward compatibility
  static const String apiBase = _baseUrl;
}
