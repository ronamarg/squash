# 🚀 Production Deployment Checklist

Use this checklist to ensure your Squash app is ready for production deployment.

## 📋 Pre-Deployment Security

### 1. Environment Variables ✓
- [ ] `lib/config/env_config.dart` is in `.gitignore`
- [ ] `.env` file is in `.gitignore`
- [ ] All API keys removed from code
- [ ] Production API URLs configured
- [ ] Firebase credentials verified

### 2. Sensitive Data ✓
- [ ] No hardcoded API keys in codebase
- [ ] No credentials in git history
- [ ] `google-services.json` in `.gitignore` (if contains sensitive data)
- [ ] `.env.example` created with placeholder values
- [ ] `env_config.example.dart` updated

### 3. Git Repository ✓
- [ ] All changes committed
- [ ] Working branch merged to main
- [ ] Repository pushed to GitHub
- [ ] No large files in repo (ML models excluded)

---

## 🐍 Backend (ML API) Deployment

### 1. Code Preparation ✓
- [ ] `requirements.txt` up to date
- [ ] `Dockerfile` created
- [ ] `Procfile` created (for Heroku/Render)
- [ ] `render.yaml` configured
- [ ] Environment variables use `os.getenv()`
- [ ] Health check endpoint works (`/health`)

### 2. Platform Setup (Choose One)

#### Option A: Render.com
- [ ] Account created
- [ ] GitHub connected
- [ ] New Web Service created
- [ ] Environment variables set:
  - [ ] `OLLAMA_API_KEY`
  - [ ] `PYTHONUNBUFFERED=1`
- [ ] Build command: `pip install -r requirements.txt`
- [ ] Start command: `python -m waitress --host=0.0.0.0 --port=$PORT ml_models.unified_api:app`
- [ ] Deploy initiated
- [ ] Health check passes

#### Option B: Railway
- [ ] Railway CLI installed
- [ ] Project initialized: `railway init`
- [ ] Environment variables set
- [ ] Deployed: `railway up`
- [ ] Custom domain configured (optional)

#### Option C: Fly.io
- [ ] Fly CLI installed
- [ ] App launched: `fly launch`
- [ ] Secrets set: `fly secrets set`
- [ ] Deployed: `fly deploy`
- [ ] Health checks configured

### 3. Testing ✓
- [ ] Health endpoint responds: `curl https://your-api.com/health`
- [ ] Code execution works: `POST /run_code`
- [ ] Code corruption works: `POST /corrupt`
- [ ] Similarity scoring works: `POST /score`
- [ ] LLM explanations work: `POST /llm/explain_code`
- [ ] Response times acceptable (< 5s)

### 4. Monitoring ✓
- [ ] Logs accessible
- [ ] Error tracking configured
- [ ] Performance monitoring enabled
- [ ] Alerts set up (optional)

---

## 🎨 Frontend (Flutter Web) Deployment

### 1. Configuration ✓
- [ ] `env_config.dart` created from example
- [ ] Production ML API URL set
- [ ] Firebase credentials configured
- [ ] All platform configs updated (if deploying mobile)

### 2. Build ✓
- [ ] Clean build: `flutter clean`
- [ ] Dependencies updated: `flutter pub get`
- [ ] No errors: `flutter analyze`
- [ ] Web build successful: `flutter build web --release`

### 3. Firebase Setup (Recommended)

#### Firebase Console
- [ ] Project created
- [ ] Authentication enabled (Email/Password, Google)
- [ ] Firestore database created
- [ ] Firestore rules configured:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
- [ ] Hosting enabled

#### Firebase CLI
- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] Logged in: `firebase login`
- [ ] Initialized: `firebase init hosting`
- [ ] `.firebaserc` configured with project ID
- [ ] `firebase.json` configured

### 4. Deploy ✓
- [ ] Built for web: `flutter build web --release`
- [ ] Deployed: `firebase deploy --only hosting`
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active

### 5. Testing ✓
- [ ] App loads in browser
- [ ] Authentication works (sign up, login, logout)
- [ ] API calls successful
- [ ] All features functional:
  - [ ] Assessment screen
  - [ ] Quiz screen
  - [ ] Code fix quiz
  - [ ] Run code screen
  - [ ] Main menu navigation
- [ ] Mobile responsive (if applicable)
- [ ] Performance acceptable (Lighthouse > 80)

---

## 📱 Mobile App Deployment (Optional)

### Android
- [ ] Keystore generated
- [ ] `key.properties` configured
- [ ] Signing configured in `build.gradle`
- [ ] Production API URL in `env_config.dart`
- [ ] APK/AAB built: `flutter build appbundle`
- [ ] Uploaded to Play Console
- [ ] Internal/Alpha testing complete

### iOS
- [ ] Apple Developer account active
- [ ] Bundle ID registered
- [ ] Signing configured in Xcode
- [ ] Production API URL in `env_config.dart`
- [ ] Built: `flutter build ios --release`
- [ ] Uploaded to App Store Connect
- [ ] TestFlight testing complete

---

## 🧪 Post-Deployment Validation

### 1. Smoke Tests ✓
- [ ] Homepage loads
- [ ] User registration works
- [ ] User login works
- [ ] Quiz data loads
- [ ] Code submission works
- [ ] Score calculation works
- [ ] Profile updates
- [ ] Logout works

### 2. Performance ✓
- [ ] Page load time < 3s
- [ ] API response time < 2s
- [ ] No console errors
- [ ] No network errors
- [ ] Memory usage acceptable

### 3. Security ✓
- [ ] HTTPS enabled
- [ ] API requires authentication
- [ ] Firestore rules enforced
- [ ] No sensitive data exposed
- [ ] CORS properly configured

### 4. Monitoring ✓
- [ ] Analytics configured (optional)
- [ ] Error tracking enabled (optional)
- [ ] Uptime monitoring set up (optional)
- [ ] Logs accessible

---

## 🔧 Troubleshooting

### Common Issues

#### "API connection failed"
- ✓ Check ML API is running
- ✓ Verify API URL in `env_config.dart`
- ✓ Check CORS configuration
- ✓ Verify network connectivity

#### "Authentication failed"
- ✓ Check Firebase config correct
- ✓ Verify auth methods enabled
- ✓ Check Firestore rules
- ✓ Clear browser cache

#### "500 Internal Server Error"
- ✓ Check API logs
- ✓ Verify environment variables
- ✓ Check Python dependencies installed
- ✓ Review recent code changes

#### "Build failed"
- ✓ Run `flutter clean`
- ✓ Delete `build/` folder
- ✓ Run `flutter pub get`
- ✓ Check for syntax errors

---

## 📊 Production URLs

After deployment, record your URLs here:

| Service | URL | Status |
|---------|-----|--------|
| **Frontend (Web)** | `https://_____.web.app` | ⬜ |
| **Backend (API)** | `https://_____.onrender.com` | ⬜ |
| **Firebase Console** | `https://console.firebase.google.com` | ⬜ |
| **API Health Check** | `https://_____.onrender.com/health` | ⬜ |

---

## 🎉 Launch Checklist

Before announcing your app:

- [ ] All tests passing
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Monitoring active
- [ ] Documentation updated
- [ ] Backup plan ready
- [ ] Support channels set up
- [ ] Terms of Service created (if needed)
- [ ] Privacy Policy created (if needed)

---

## 📞 Support Resources

- **Deployment Guide**: `DEPLOYMENT.md`
- **README**: `README.md`
- **Developer Guide**: `README-DEV.md`
- **ML Models**: `ml_models/README.md`

---

**✅ Once all items are checked, you're ready to launch! 🚀**
