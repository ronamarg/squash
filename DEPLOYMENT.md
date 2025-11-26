# 🚀 Squash Deployment Guide

Complete guide for deploying the Squash application to production.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Backend Deployment (ML API)](#backend-deployment-ml-api)
- [Frontend Deployment (Flutter Web)](#frontend-deployment-flutter-web)
- [Environment Variables](#environment-variables)
- [Platform-Specific Guides](#platform-specific-guides)
- [Post-Deployment](#post-deployment)

---

## 🏗️ Architecture Overview

```
┌─────────────────┐         ┌──────────────────┐
│   Flutter Web   │ ──────> │   Python ML API  │
│  (Firebase)     │   HTTPS │   (Render/Fly)   │
└─────────────────┘         └──────────────────┘
         │                           │
         │                           │
         ▼                           ▼
┌─────────────────┐         ┌──────────────────┐
│  Firebase Auth  │         │  Ollama LLM API  │
│   & Firestore   │         │    (External)    │
└─────────────────┘         └──────────────────┘
```

**Components:**
1. **Frontend**: Flutter web app (static hosting)
2. **Backend**: Python Flask ML API (compute platform)
3. **Database**: Firebase Firestore (managed)
4. **LLM**: Ollama API (external service)

---

## ✅ Prerequisites

### Tools Required
- Git
- Flutter SDK (3.9.2+)
- Python 3.11+
- Docker (optional, for containerized deployment)
- Firebase CLI (for Firebase Hosting)

### Accounts Required
- Firebase account (free tier)
- Render/Railway/Fly.io account (free tier available)
- GitHub account (for repository)
- Ollama API key (for LLM features)

---

## 🐍 Backend Deployment (ML API)

The ML API can be deployed to several platforms. Choose one:

### Option 1: Render.com (Recommended - Free Tier)

#### Step 1: Prepare Repository
```bash
# Ensure all deployment files are committed
git add .
git commit -m "Prepare for deployment"
git push origin main
```

#### Step 2: Deploy to Render
1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Configure:
   - **Name**: `squash-ml-api`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python -m waitress --host=0.0.0.0 --port=$PORT ml_models.unified_api:app`
   - **Plan**: `Free`

#### Step 3: Set Environment Variables
In Render dashboard → Environment:
```
OLLAMA_API_KEY=your_ollama_api_key_here
PYTHONUNBUFFERED=1
```

#### Step 4: Deploy
- Click "Create Web Service"
- Wait for deployment (5-10 minutes first time)
- Note your API URL: `https://squash-ml-api.onrender.com`

#### Health Check
```bash
curl https://squash-ml-api.onrender.com/health
```

---

### Option 2: Railway (Alternative - $5/month free credit)

#### Step 1: Install Railway CLI
```bash
npm install -g @railway/cli
railway login
```

#### Step 2: Deploy
```bash
cd c:\dev\squash
railway init
railway up
```

#### Step 3: Set Environment Variables
```bash
railway variables set OLLAMA_API_KEY=your_key_here
railway variables set PYTHONUNBUFFERED=1
```

#### Step 4: Get URL
```bash
railway domain
```

---

### Option 3: Fly.io (Alternative)

#### Step 1: Install Fly CLI
```powershell
iwr https://fly.io/install.ps1 -useb | iex
fly auth login
```

#### Step 2: Create Fly Configuration
```bash
cd c:\dev\squash
fly launch --no-deploy
```

Edit `fly.toml`:
```toml
app = "squash-ml-api"

[build]
  dockerfile = "Dockerfile"

[env]
  PYTHONUNBUFFERED = "1"
  PORT = "8080"

[[services]]
  http_checks = []
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    force_https = true
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
```

#### Step 3: Set Secrets
```bash
fly secrets set OLLAMA_API_KEY=your_key_here
```

#### Step 4: Deploy
```bash
fly deploy
```

---

### Option 4: Docker (Self-Hosted)

#### Build and Run Locally
```bash
# Build image
docker build -t squash-ml-api .

# Run container
docker run -d -p 5001:5001 \
  -e OLLAMA_API_KEY=your_key_here \
  --name squash-api \
  squash-ml-api
```

#### Or Use Docker Compose

---

## 📈 Pre-Deployment: ML Benchmarks

Run quick performance checks and capture metrics for documentation.

### Benchmark Commands
```powershell
# Activate venv
```bash
# Create .env file
echo "OLLAMA_API_KEY=your_key_here" > .env

# Start services
docker-compose up -d

# View logs
docker-compose logs -f ml-api
```


### Record Results
Copy outputs into `docs/ML_PERFORMANCE.md` under each model section.
---

## 🎨 Frontend Deployment (Flutter Web)

### Option 1: Firebase Hosting (Recommended - Free)

#### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### Step 2: Configure Environment
```bash
# Copy example and fill in values
cp lib/config/env_config.example.dart lib/config/env_config.dart
```

Edit `lib/config/env_config.dart`:
```dart
class EnvConfig {
  // Use your deployed ML API URL
  static const String mlApiBaseUrl = 'https://squash-ml-api.onrender.com';
  
  // Fill in your Firebase credentials
  static const String firebaseWebApiKey = 'your_firebase_api_key';
  static const String firebaseProjectId = 'your_project_id';
  // ... etc
}
```

#### Step 3: Initialize Firebase
```bash
firebase init hosting
```

Configure:
- **Public directory**: `build/web`
- **Single-page app**: `Yes`
- **Automatic builds**: `No`

#### Step 4: Build Flutter Web
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
```

#### Step 5: Deploy
```bash
firebase deploy --only hosting
```

Your app will be live at: `https://your-project.web.app`

---

### Option 2: Vercel (Alternative)

#### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

#### Step 2: Build and Deploy
```bash
# Build
flutter build web --release

# Deploy
cd build/web
vercel --prod
```

---

### Option 3: Netlify (Alternative)

#### Step 1: Build
```bash
flutter build web --release
```

#### Step 2: Deploy via Netlify CLI
```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

Or drag and drop `build/web` folder to [Netlify Drop](https://app.netlify.com/drop).

---

## 🔐 Environment Variables

### Backend (.env)
```env
# Required
OLLAMA_API_KEY=your_ollama_api_key_here

# Optional
OLLAMA_API_URL=https://ollama.com/api/chat
OLLAMA_MODEL=gpt-oss:20b
ML_API_PORT=5001
PYTHONUNBUFFERED=1
```

### Frontend (lib/config/env_config.dart)
```dart
class EnvConfig {
  // ML API - Use deployed URL
  static const String mlApiBaseUrl = 'https://your-api.onrender.com';
  
  // Firebase - Get from Firebase Console
  static const String firebaseWebApiKey = 'AIza...';
  static const String firebaseWebAppId = '1:538...';
  static const String firebaseProjectId = 'your-project';
  static const String firebaseAuthDomain = 'your-project.firebaseapp.com';
  static const String firebaseStorageBucket = 'your-project.appspot.com';
  // ... etc
}
```

---

## 📱 Platform-Specific Guides

### Android App Deployment

#### Step 1: Configure Signing
Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

#### Step 2: Generate Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

#### Step 3: Build APK/AAB
```bash
# APK (for testing)
flutter build apk --release

# AAB (for Play Store)
flutter build appbundle --release
```

#### Step 4: Update env_config.dart
Set ML API URL to production:
```dart
static const String mlApiBaseUrl = 'https://your-api.onrender.com';
```

---

### iOS App Deployment

#### Step 1: Configure Xcode
```bash
open ios/Runner.xcworkspace
```

Set:
- Team & Bundle Identifier
- Signing & Capabilities

#### Step 2: Build
```bash
flutter build ios --release
```

---

## 🧪 Post-Deployment

### 1. Verify Backend Health
```bash
curl https://your-api.onrender.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "services": {
    "skill_classifier": true,
    "code_corruptor": true,
    "code_similarity": true,
    "code_execution": true
  }
}
```

### 2. Test Key Endpoints

#### Test Code Execution
```bash
curl -X POST https://your-api.onrender.com/run_code \
  -H "Content-Type: application/json" \
  -d '{"code": "print(\"Hello, World!\")", "language": "python"}'
```

#### Test Code Corruption
```bash
curl -X POST https://your-api.onrender.com/corrupt \
  -H "Content-Type: application/json" \
  -d '{"code": "def hello():\n    print(\"Hi\")", "corruption_level": 0.3}'
```

### 3. Monitor Logs

**Render:**
```bash
# Via dashboard or CLI
render logs -t web-service-name
```

**Railway:**
```bash
railway logs
```

**Fly:**
```bash
fly logs
```

### 4. Configure Custom Domain (Optional)

#### Firebase Hosting
```bash
firebase hosting:channel:deploy production
```

Then add domain in Firebase Console → Hosting → Add custom domain

#### Render/Railway
Add custom domain in dashboard settings

---

## 🔧 Troubleshooting

### Backend Issues

#### API Returns 500 Errors
- Check environment variables are set
- Verify OLLAMA_API_KEY is valid
- Check logs for Python errors

#### Cold Start Delays
- Render free tier sleeps after 15 min inactivity
- First request after sleep takes 30-60s
- Consider paid tier or use Railway

#### Out of Memory
- Reduce model loading
- Use smaller models
- Upgrade to paid tier with more RAM

### Frontend Issues

#### API Calls Fail (CORS)
- Ensure ML API has CORS enabled (already configured)
- Check API URL is correct in env_config.dart

#### Firebase Auth Not Working
- Verify Firebase configuration
- Check firestore.rules allow read/write
- Enable authentication methods in Firebase Console

#### Build Fails
```bash
flutter clean
flutter pub get
flutter build web --release
```

---

## 💰 Cost Estimates

### Free Tier Limits

| Service | Free Tier | Limits |
|---------|-----------|--------|
| **Render** | ✅ Yes | 750 hrs/month, sleeps after 15 min |
| **Railway** | ✅ $5/month credit | ~21 hrs/month |
| **Fly.io** | ✅ Yes | 3 shared CPUs, 256MB RAM |
| **Firebase Hosting** | ✅ Yes | 10 GB storage, 360 MB/day transfer |
| **Firebase Firestore** | ✅ Yes | 1 GB storage, 50K reads/day |
| **Vercel** | ✅ Yes | 100 GB bandwidth |
| **Netlify** | ✅ Yes | 100 GB bandwidth |

### Recommended Free Setup
- **Backend**: Render (free tier)
- **Frontend**: Firebase Hosting (free tier)
- **Database**: Firebase Firestore (free tier)
- **Total Cost**: $0/month 🎉

---

## 📞 Support

If you encounter issues:
1. Check logs first
2. Review this guide
3. Open an issue on GitHub
4. Check platform-specific documentation

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] All environment variables configured
- [ ] API keys secured (not in code)
- [ ] `.gitignore` updated
- [ ] Code tested locally
- [ ] Firebase project created
- [ ] Database rules configured

### Backend Deployment
- [ ] ML API deployed
- [ ] Health check passing
- [ ] Environment variables set
- [ ] API URL noted

### Frontend Deployment
- [ ] `env_config.dart` updated with production API URL
- [ ] Firebase credentials added
- [ ] Flutter web built
- [ ] Deployed to hosting
- [ ] App tested in browser

### Post-Deployment
- [ ] All features tested
- [ ] Auth working
- [ ] API calls successful
- [ ] Performance acceptable
- [ ] Monitoring set up

---

**🎉 Your Squash app is now live!**

Frontend: `https://your-project.web.app`  
Backend: `https://your-api.onrender.com`
