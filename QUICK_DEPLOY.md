# 🚀 Quick Deployment Reference

Ultra-quick reference for deploying Squash.

## 🔥 Fastest Free Deployment (5 minutes)

### Backend (ML API) → Render
```bash
# 1. Push to GitHub
git add .
git commit -m "Ready for deployment"
git push origin main

# 2. Deploy to Render
# Go to: https://dashboard.render.com
# Click: New + → Web Service
# Connect repo, use these settings:
#   Build: pip install -r requirements.txt
#   Start: python -m waitress --host=0.0.0.0 --port=$PORT ml_models.unified_api:app
# Add env var: OLLAMA_API_KEY=your_key

# 3. Note your API URL
# https://squash-ml-api.onrender.com
```

### Frontend (Flutter) → Firebase
```bash
# 1. Configure env_config.dart
cp lib/config/env_config.example.dart lib/config/env_config.dart
# Edit: Set mlApiBaseUrl to your Render URL

# 2. Build & Deploy
flutter build web --release
firebase login
firebase deploy --only hosting

# Done! Your app is live at: https://your-project.web.app
```

---

## 📋 Essential Commands

### Build Commands
```bash
# Flutter Web
flutter clean && flutter pub get
flutter build web --release

# Python API (local test)
cd ml_models
python unified_api.py
```

### Deploy Commands
```bash
# Firebase
firebase deploy --only hosting

# Render (via dashboard)
# Just push to GitHub

# Railway
railway up

# Fly.io
fly deploy

# Docker
docker build -t squash-ml-api .
docker run -p 5001:5001 --env-file .env squash-ml-api
```

### Test Commands
```bash
# Health check
curl https://your-api.onrender.com/health

# Test code execution
curl -X POST https://your-api.onrender.com/run_code \
  -H "Content-Type: application/json" \
  -d '{"code":"print(42)","language":"python"}'
```

---

## 🔐 Environment Setup

### Backend (.env)
```env
OLLAMA_API_KEY=your_ollama_key_here
PYTHONUNBUFFERED=1
```

### Frontend (lib/config/env_config.dart)
```dart
class EnvConfig {
  static const String mlApiBaseUrl = 'https://your-api.onrender.com';
  static const String firebaseProjectId = 'your-project-id';
  // ... rest of Firebase config
}
```

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| **API not responding** | Check Render logs, verify env vars |
| **CORS error** | Already configured, check API URL |
| **Auth fails** | Verify Firebase config, enable auth methods |
| **Build fails** | `flutter clean && flutter pub get` |
| **500 error** | Check API logs for Python errors |

---

## 💰 Cost Summary

| Service | Free Tier |
|---------|-----------|
| Render | 750 hrs/month |
| Firebase Hosting | 10 GB storage |
| Firebase Firestore | 1 GB + 50K reads/day |
| **Total** | **$0/month** 🎉 |

---

## 📚 Full Documentation

- Complete Guide: `DEPLOYMENT.md`
- Checklist: `PRODUCTION_CHECKLIST.md`
- Dev Guide: `README-DEV.md`

---

**Need help?** Open an issue or check the full deployment guide.
