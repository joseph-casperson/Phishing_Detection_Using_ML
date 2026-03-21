// =============================================================================
// mongo_setup.js
// Phishing Detection ML Project — MongoDB Experiment Log Setup
// =============================================================================
// HOW TO RUN:
//   mongosh mongo_setup.js
//
// WHAT THIS DOES:
//   1. Creates the 'phishdb' database
//   2. Creates the 'model_runs' collection for logging ML experiment results
//   3. Creates the 'preprocessing_log' collection for logging cleaning steps
//   4. Creates indexes for fast querying
//   5. Inserts example/template documents so the schema is visible in Compass
//
// AFTER RUNNING:
//   Verify with:  mongosh --eval "use phishdb; db.model_runs.find().pretty()"
//   Or open MongoDB Compass → connect to localhost:27017 → browse phishdb
// =============================================================================


// ── Switch to (or create) the phishdb database ────────────────────────────────
db = db.getSiblingDB("phishdb");
print("✓ Using database: phishdb");


// =============================================================================
// COLLECTION 1: model_runs
// One document per classifier × train/test split combination.
// Python's 04_modeling.ipynb inserts into this collection after each run.
//
// Document schema:
//   model        → classifier name (string)
//   language     → "python" or "r"
//   split        → e.g. "80/20" (string label)
//   train_size   → 0.80 (float)
//   accuracy     → 0.9712 (float)
//   precision    → 0.9701 (float)
//   recall       → 0.9688 (float)
//   f1           → 0.9694 (float)
//   notes        → any free-text observation
//   timestamp    → ISODate when the run completed
// =============================================================================

db.createCollection("model_runs");
print("✓ Collection created: model_runs");

// Index on model name for fast filtering by classifier
db.model_runs.createIndex({ model: 1 });

// Index on split for fast filtering by train/test ratio
db.model_runs.createIndex({ split: 1 });

// Compound index — most common query: "all runs for this model at this split"
db.model_runs.createIndex({ model: 1, split: 1 });

// Index on timestamp to sort runs chronologically
db.model_runs.createIndex({ timestamp: -1 });

print("✓ Indexes created on model_runs");

// Insert 3 template documents — one per model at the 80/20 split
// These act as schema examples visible in MongoDB Compass.
// Your Python notebook will overwrite/supplement these with real results.
db.model_runs.insertMany([
    {
        model:       "LogisticRegression",
        language:    "python",
        split:       "80/20",
        train_size:  0.80,
        accuracy:    null,     // fill in after running notebook
        precision:   null,
        recall:      null,
        f1:          null,
        notes:       "Baseline linear classifier. Interpretable but assumes linear separability.",
        timestamp:   new Date()
    },
    {
        model:       "RandomForest",
        language:    "python",
        split:       "80/20",
        train_size:  0.80,
        accuracy:    null,
        precision:   null,
        recall:      null,
        f1:          null,
        notes:       "Ensemble method. Handles nonlinear feature interactions. Expected top performer.",
        timestamp:   new Date()
    },
    {
        model:       "SVM",
        language:    "python",
        split:       "80/20",
        train_size:  0.80,
        accuracy:    null,
        precision:   null,
        recall:      null,
        f1:          null,
        notes:       "Effective in high-dimensional spaces. RBF kernel for nonlinear boundaries.",
        timestamp:   new Date()
    }
]);

print("✓ Template documents inserted into model_runs");


// =============================================================================
// COLLECTION 2: preprocessing_log
// One document per cleaning operation performed in Phase 2.
// Python's 02_preprocessing.ipynb appends to this collection as it runs.
//
// Document schema:
//   operation      → what was done (string)
//   rows_before    → row count before this operation
//   rows_after     → row count after this operation
//   rows_affected  → rows_before - rows_after
//   detail         → free-text explanation
//   timestamp      → when the operation ran
// =============================================================================

db.createCollection("preprocessing_log");
print("✓ Collection created: preprocessing_log");

db.preprocessing_log.createIndex({ timestamp: 1 });

// Insert one template document showing the expected schema
db.preprocessing_log.insertOne({
    operation:     "example_template",
    rows_before:   null,
    rows_after:    null,
    rows_affected: null,
    detail:        "This is a schema example. Real entries are inserted by 02_preprocessing.ipynb.",
    timestamp:     new Date()
});

print("✓ Template document inserted into preprocessing_log");


// =============================================================================
// USEFUL QUERIES TO RUN AFTER YOUR NOTEBOOKS COMPLETE
// Paste these into mongosh one at a time.
// =============================================================================

print("\n────────────────────────────────────────────────────────────");
print("Setup complete. After running your notebooks, try these queries:");
print("");
print("// All model runs sorted by F1 score (best first):");
print('db.model_runs.find({f1: {$ne: null}}).sort({f1: -1}).pretty()');
print("");
print("// Compare all splits for Random Forest:");
print('db.model_runs.find({model: "RandomForest"}).sort({train_size: 1}).pretty()');
print("");
print("// Best accuracy across all models and splits:");
print('db.model_runs.find().sort({accuracy: -1}).limit(1).pretty()');
print("");
print("// Average F1 score per model (aggregation pipeline):");
print('db.model_runs.aggregate([');
print('  { $match: { f1: { $ne: null } } },');
print('  { $group: { _id: "$model", avg_f1: { $avg: "$f1" } } },');
print('  { $sort: { avg_f1: -1 } }');
print('])');
print("");
print("// Full preprocessing audit log in order:");
print('db.preprocessing_log.find().sort({timestamp: 1}).pretty()');
print("────────────────────────────────────────────────────────────\n");
