# Squash Developer Guide (README-DEV)

This guide is for collaborators, contributors, and maintainers. The root `README.md` is end‑user oriented; this file contains implementation, environment, and workflow details.

---
## 1. Purpose & Audience
For engineers working on the Flutter app, Python ML services, or data. Focus: reproducible setup, consistent practices, and safe handling of secrets.

---
## 2. Prerequisites
Install / have available before cloning:
- Flutter SDK (stable channel) – see `docs/README_FLUTTER_SETUP.md`
- Android Studio (AVD) OR Xcode (macOS) for simulators
- Python 3.10+ (venv recommended)
- Git + Git LFS (if large model artifacts are added later)
- Node.js (optional; currently not required but useful for tooling)

Check versions:
```bash
flutter --version
python --version
git --version
```

---
## 3. Environment & Secrets Setup
We externalize sensitive values (Firebase, API keys) into `lib/env_config.dart` (ignored by git).

Initial steps:
```bash
cp lib/env_config.example.dart lib/env_config.dart
```
Fill placeholders (DO NOT COMMIT real secrets). See `ENV_SETUP.md` for parameter descriptions.

Validation checklist:
- File `lib/env_config.dart` exists (not empty)
- App builds without hard‑coded keys
- No secrets appear in `git diff`

---
## 4. Secret Handling Policy
- Never commit real API keys or private URLs.
- Use example placeholders in `env_config.example.dart`.
- If a secret accidentally commits: rotate the key; force-push removal only if necessary.

---
## 5. Firebase Setup (High Level)
1. Create Firebase project (Console).
2. Enable Authentication (Google, Email/Password).
3. Download platform config files (Google Services) per platform if needed.
4. Add API keys / IDs into `env_config.dart` placeholders.
5. Confirm initialization code uses `EnvConfig` indirection (already refactored).

(See future dedicated Firebase doc if needed.)

---
## 6. ML Backend Overview & Ports
Recommended local ports:
- Similarity: `5000`
- Corruptor: `5001`
- Skill classifier (future API): `5002`

Update `EnvConfig` or derived `Config` accessors rather than hard-coding.

---
## 7. Running Services (Multi-Terminal)
```bash
# Terminal 1 – Flutter
flutter run

# Terminal 2 – Code Similarity API
cd ml_models/code_similarity
python api.py

# Terminal 3 – Code Corruptor API
cd ml_models/code_corruptor
python api.py

# (Future) Skill Classifier API
cd ml_models/skill_classifier
python api.py  # after API implementation
```
Android emulator uses `10.0.2.2` to reach host services. Adjust IP for physical devices.

---
## 8. Directory Structure (Condensed)
```
squash/
├── lib/                  # Flutter UI & logic
│   ├── services/         # Dart API service wrappers
│   ├── models/           # (Domain models)
│   └── ...
├── ml_models/            # Python ML modules
│   ├── skill_classifier/
│   ├── code_similarity/
│   ├── code_corruptor/
│   └── shared/
├── data/                 # Raw & processed datasets
├── docs/                 # Documentation & guides
├── ENV_SETUP.md          # Environment guide
├── README.md             # User-facing overview
├── README-DEV.md         # This file
└── requirements*.txt     # Python dependency sets
```

---
## 9. Development Workflow
Branch strategy (example):
- `main` – stable
- feature branches: `feat/<short-desc>`
- fix branches: `fix/<issue>`
- docs branches: `docs/<topic>`

Suggested flow:
```bash
git checkout -b feat/new-screen
# implement changes
git add .
git commit -m "feat: add new screen"
git push origin feat/new-screen
```
Create PR → review → squash merge if appropriate.

Commit message convention:
- `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`

---
## 10. Flutter Development Tips
- Use `flutter pub get` after dependency changes.
- Hot reload: press `r`; full restart: `R`.
- Avoid long blocking operations in UI; use async + mounted checks (pattern already in code).
- Keep widget rebuild scope minimal (prefer small widgets).

---
## 11. API Services Integration
Service wrappers live in `lib/services/`. For new APIs:
1. Implement Python Flask/FastAPI server under `ml_models/<new_model>/api.py`.
2. Add Dart wrapper in `lib/services/`.
3. Extend `EnvConfig` for new base URL.
4. Document endpoints in service README.

See `lib/services/README.md` for existing patterns.

---
## 12. Testing & Debugging
Manual testing focus currently (no formal test suite yet):
- Verify API responses via `curl` or Postman.
- Confirm Flutter service methods handle error states (network failures).
- Check logs for setState after dispose; ensure mounted guards.

Example curl:
```bash
curl -X POST http://127.0.0.1:5000/score \
  -H "Content-Type: application/json" \
  -d '{"student_code":"print(1)","canonical_code":"print(1)"}'
```

---
## 13. Adding a New ML Model
1. Create directory `ml_models/<model_name>/`.
2. Add `README.md` (purpose, usage, training).
3. Update `ml_models/README.md` table.
4. Add dependencies to `requirements.txt` or `requirements_dl.txt`.
5. Provide API (`api.py`) if needed by Flutter.

---
## 14. Adding a New Flutter Service
1. Define endpoints (Python side).
2. Add constants / factory methods in Dart service file.
3. Use `http` package; keep JSON encode/decode isolated.
4. Return typed models if complexity grows (create under `lib/models/`).
5. Add minimal error handling and timeouts.

---
## 15. Troubleshooting
| Issue | Cause | Fix |
|-------|-------|-----|
| Emulator cannot reach API | Wrong host/IP | Use `10.0.2.2` on Android emulator |
| 404 on endpoint | API not started or port mismatch | Start correct `api.py`; verify port in `EnvConfig` |
| setState after dispose warning | Async callback after navigation | Guard with `if (!mounted) return;` |
| Dependency import error (Python) | Missing install / wrong venv | Activate venv; reinstall requirements |
| Flutter build fails on Windows path | Spaces in path | Move project & Flutter SDK to space-free path |

---
## 16. Quick Commands Cheat Sheet
```bash
# Flutter
flutter clean
flutter pub get
flutter run

# Similarity API
cd ml_models/code_similarity
python api.py

# Corruptor API
cd ml_models/code_corruptor
python api.py

# Train Skill Classifier
cd ml_models/skill_classifier
python train.py
```

---
## 17. Contribution Checklist
- [ ] Branch created (not on main)
- [ ] No secrets added
- [ ] Updated relevant README(s)
- [ ] Ran app & APIs locally
- [ ] Linted (if lint rules added later)
- [ ] Clear commit message

---
## 18. Roadmap (Snapshot)
- Implement Skill Classifier API wrapper
- Add automated test suite (Flutter + Python)
- Introduce central logging / monitoring
- CI pipeline for build + lint

---
## 19. References
- `README.md` (user overview)
- `ENV_SETUP.md` (detailed environment explanation)
- `ml_models/README.md` (ML index)
- `lib/services/README.md` (service integration)
- `docs/` folder (extended guides)

---
**Questions?** Open an issue or start a discussion before large structural changes.
