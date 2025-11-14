# Flutter Services - API Integration Guide

## Overview

The Flutter app communicates with Python ML models through REST APIs. The directory reorganization does NOT affect the app since it only changed Python file locations, not API endpoints.

## Service Architecture

```
lib/services/
├── code_scorer.dart          → ml_models/code_similarity/api.py
├── code_corruptor_service.dart → ml_models/code_corruptor/api.py
└── (future services)         → ml_models/skill_classifier/api.py
```

## Current Services

### 1. Code Scorer (`code_scorer.dart`)
**Purpose:** Score similarity between student and canonical code

**API Endpoint:** `POST ${Config.apiBase}/score_code`

**Backend:** `ml_models/code_similarity/api.py`

**Start Backend:**
```bash
cd ml_models\code_similarity
python api.py
```

**Usage:**
```dart
final score = await CodeScorer.scoreCode(studentCode, correctCode);
```

---

### 2. Code Corruptor (`code_corruptor_service.dart`)
**Purpose:** Generate buggy code from correct code (AI-powered)

**API Endpoints:**
- `POST /corrupt` - Corrupt single code
- `POST /generate_quiz` - Generate quiz question
- `POST /corrupt/batch` - Batch corruption
- `GET /health` - Health check

**Backend:** `ml_models/code_corruptor/api.py`

**Start Backend:**
```bash
cd ml_models\code_corruptor
python api.py
```

**Usage:**
```dart
final service = CodeCorruptorService();
final quiz = await service.generateQuiz(
  correctCode: solution,
  question: 'Fix the bug:',
  difficulty: 'medium',
);
```

---

### 3. Skill Assessment (in screens)
**Purpose:** Predict student proficiency level

**API Endpoint:** `POST ${Config.apiBase}/predict_level`

**Backend:** Skill classifier model (needs API wrapper)

**TODO:** Create `ml_models/skill_classifier/api.py`

---

## Configuration

All API URLs are configured in `lib/config.dart`:

```dart
class Config {
  static const String similarityApiBase = 'http://10.0.2.2:5000';
  static const String corruptorApiBase = 'http://10.0.2.2:5001';
  static const String skillApiBase = 'http://10.0.2.2:5002';
}
```

### For Different Platforms:
- **Android Emulator:** `http://10.0.2.2:PORT`
- **iOS Simulator:** `http://127.0.0.1:PORT`
- **Physical Device:** `http://<YOUR_LAN_IP>:PORT`

---

## Running Multiple APIs

Each ML model can run on a different port:

### Terminal 1 - Code Similarity (Port 5000)
```bash
cd ml_models\code_similarity
python api.py
```

### Terminal 2 - Code Corruptor (Port 5001)
```bash
cd ml_models\code_corruptor
set PORT=5001
python api.py
```

### Terminal 3 - Skill Classifier (Port 5002)
```bash
cd ml_models\skill_classifier
# TODO: Create api.py
set PORT=5002
python api.py
```

---

## API Development

### Creating New Service

1. **Python Side:** Create Flask API in `ml_models/your_model/api.py`
```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/your_endpoint', methods=['POST'])
def your_endpoint():
    data = request.get_json()
    result = your_model_function(data)
    return jsonify({'result': result})

if __name__ == '__main__':
    app.run(port=5003)
```

2. **Dart Side:** Create service in `lib/services/your_service.dart`
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class YourService {
  static Future<dynamic> yourMethod(data) async {
    final response = await http.post(
      Uri.parse('${Config.yourApiBase}/your_endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': data}),
    );
    return jsonDecode(response.body);
  }
}
```

3. **Config:** Add to `lib/config.dart`
```dart
static const String yourApiBase = 'http://10.0.2.2:5003';
```

---

## No Refactoring Needed! ✅

**Why?**
- Flutter talks to APIs via HTTP
- API endpoints haven't changed
- Only Python file locations changed
- Services are already properly abstracted

**What Changed:**
- Python files moved to `ml_models/`
- Better organization
- Easier to maintain

**What Stayed Same:**
- All API endpoints
- Service interfaces
- Flutter app code
- HTTP communication

---

## Dependencies

Make sure `pubspec.yaml` includes:
```yaml
dependencies:
  http: ^1.1.0
```

---

## Testing APIs

Use this to test if APIs are running:

```dart
// Check similarity API
final response = await http.get(Uri.parse('http://10.0.2.2:5000/'));

// Check corruptor API  
final response = await http.get(Uri.parse('http://10.0.2.2:5001/health'));
```

---

## Summary

✅ **No Flutter refactoring needed**
✅ **Services work with reorganized structure**
✅ **Just start the Python APIs and go!**
✅ **Clean separation: Flutter ↔ HTTP ↔ Python**
