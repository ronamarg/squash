class Config {
  // Base API configuration
  // Change these values depending on where your APIs run:
  // - Android emulator (default) -> 'http://10.0.2.2:PORT'
  // - iOS simulator -> 'http://127.0.0.1:PORT'
  // - Physical device -> 'http://<your-machine-lan-ip>:PORT'
  
  // Code Similarity API (runs on port 5000)
  static const String similarityApiBase = 'http://10.0.2.2:5000';
  
  // Code Corruptor API (runs on port 5001 - or configure in api.py)
  static const String corruptorApiBase = 'http://10.0.2.2:5001';
  
  // Skill Classifier API (runs on port 5002 - or configure in api.py)
  static const String skillApiBase = 'http://10.0.2.2:5002';
  
  // Backward compatibility - defaults to similarity API
  static const String apiBase = similarityApiBase;
}
