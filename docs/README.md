# Squash ML Models Documentation

Documentation for all machine learning models and algorithms in the Squash project.

## 📑 Documentation Files

- **[CODE_CORRUPTION_GUIDE.md](CODE_CORRUPTION_GUIDE.md)** - Complete guide for the deep learning code corruptor
- **[QUICK_REFERENCE.txt](QUICK_REFERENCE.txt)** - Quick commands for all ML operations
- **[DIRECTORY_TREE.txt](DIRECTORY_TREE.txt)** - Visual project structure

---

## 📁 ML Models Directory Structure

```
squash/
├── ml_models/                    # All ML models and algorithms
│   ├── skill_classifier/         # Random Forest proficiency classifier
│   │   ├── train.py
│   │   ├── rf_model.joblib       # Trained model
│   │   └── README.md
│   │
│   ├── code_similarity/          # Code similarity scoring
│   │   ├── scorer.py             # Main similarity algorithm
│   │   ├── api.py                # Flask API
│   │   ├── scoring.py.bak
│   │   └── README.md
│   │
│   ├── code_corruptor/          # Deep learning bug generator
│   │   ├── train.py
│   │   ├── infer.py
│   │   ├── evaluate.py
│   │   ├── analyze_data.py
│   │   ├── api.py
│   │   └── README.md
│   │
│   ├── shared/                   # Shared utilities
│   │   └── normalize_code.py
│   │
│   └── README.md                 # This file
│
├── data/                         # All datasets
│   ├── raw/                      # Original/raw data
│   │   ├── initial_dataset.xlsx
│   │   └── code_corrupt/
│   │       └── code_bug_fix_pairs.csv (6,237 pairs)
│   │
│   └── processed/                # Processed/cleaned data
│       ├── master_dataset.csv
│       └── final_dataset.csv
│
├── lib/                          # Flutter app code
│   └── services/
│       └── code_scorer.dart
│
├── requirements.txt              # Basic ML dependencies
├── requirements_dl.txt           # Deep learning dependencies
├── CODE_CORRUPTION_GUIDE.md      # Detailed DL guide
├── CODE_CORRUPTOR_README.md      # Corruptor overview
├── QUICK_REFERENCE.txt           # Quick reference
└── README.md                     # Main project README
```

## 🎯 What Changed

### Before (Messy)
```
✗ train_classifier.py
✗ string_scorer.py
✗ model_api.py
✗ normalize.py
✗ rf_model.joblib
✗ train_code_corruptor.py
✗ infer_code_corruptor.py
✗ evaluate_corruptor.py
✗ analyze_dataset.py
✗ api_server.py
✗ final_dataset.csv
✗ master_dataset.csv
✗ initial_dataset.xlsx
✗ -code_corrupt/
... all mixed in root directory
```

### After (Organized)
```
✓ ml_models/
    ✓ skill_classifier/
    ✓ code_similarity/
    ✓ code_corruptor/
    ✓ shared/
✓ data/
    ✓ raw/
    ✓ processed/
```

## 🚀 Quick Access

### Train Skill Classifier
```bash
cd ml_models\skill_classifier
python train.py
```

### Run Code Similarity API
```bash
cd ml_models\code_similarity
python api.py
```

### Train Code Corruptor
```bash
cd ml_models\code_corruptor
python train.py
```

### Analyze Bug Dataset
```bash
cd ml_models\code_corruptor
python analyze_data.py
```

## 📊 Models Summary

| Model | Type | Purpose | Location |
|-------|------|---------|----------|
| **Skill Classifier** | Random Forest | Classify student proficiency | `ml_models/skill_classifier/` |
| **Code Similarity** | Custom Algorithm | Score code similarity | `ml_models/code_similarity/` |
| **Code Corruptor** | CodeT5 Transformer | Generate buggy code | `ml_models/code_corruptor/` |

## 📦 Installation

### Basic ML (Skill Classifier, Similarity)
```bash
pip install -r requirements.txt
```

### Deep Learning (Code Corruptor)
```bash
pip install -r requirements_dl.txt
```

## 📖 Documentation

Each model has its own README:
- `ml_models/README.md` - Overview of all models
- `ml_models/skill_classifier/README.md` - Skill classifier details
- `ml_models/code_similarity/README.md` - Similarity scorer details
- `ml_models/code_corruptor/README.md` - Code corruptor details

## 🔗 Integration

All models can be used via:
1. **Python imports** - Direct module imports
2. **REST APIs** - Flask servers in each module
3. **Flutter services** - Dart service classes in `lib/services/`

## 🗂️ Data Organization

### Raw Data (`data/raw/`)
Original, unprocessed datasets:
- Student code submissions
- Bug-fix pairs from GitHub

### Processed Data (`data/processed/`)
Cleaned, normalized, scored datasets:
- Ready for model training
- Feature-engineered data

## 🎯 Benefits of This Structure

✅ **Clear separation** - Each model in its own directory
✅ **Easy to navigate** - Find code and data quickly
✅ **Scalable** - Easy to add new models
✅ **Self-documenting** - README in each directory
✅ **Data organized** - Raw vs. processed separation
✅ **Version control friendly** - Logical git structure

## 🔧 Path Updates

All file paths have been updated to work with the new structure:
- ✅ Training scripts point to `../../data/`
- ✅ APIs reference correct model paths
- ✅ Documentation updated
- ✅ No broken imports

## 📝 Next Steps

1. ✅ Structure organized
2. ✅ Files moved
3. ✅ Paths updated
4. ✅ Documentation created
5. ⏭️ Ready to use!

## 🤝 Contributing

When adding new models:
1. Create subdirectory under `ml_models/`
2. Add README.md in that directory
3. Update `ml_models/README.md`
4. Use `data/` for datasets
5. Use `ml_models/shared/` for common utilities

---

**Previous mess:** 15+ files scattered in root
**Current organization:** Clean, modular, professional structure

Enjoy your organized workspace! 🎉
