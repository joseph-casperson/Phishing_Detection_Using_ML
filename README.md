# Phishing URL Detection — Machine Learning Pipeline

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python&logoColor=white)
![R](https://img.shields.io/badge/R-4.3-276DC3?style=flat-square&logo=r&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-7.0-47A248?style=flat-square&logo=mongodb&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=flat-square&logo=jupyter&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-Server-E95420?style=flat-square&logo=ubuntu&logoColor=white)

An end-to-end machine learning pipeline that classifies phishing URLs using structured feature analysis. Built on a self-hosted Ubuntu server with PostgreSQL and MongoDB as the data backend. Implements and compares supervised classifiers in both **Python** and **R**.

> CS 4200 Final Project — Covers Chapters 4/5, 8, 9, and 11

📄 **[View Full Project Flow →](https://joseph-casperson.github.io/Phishing_Detection_Using_ML/docs/PROJECT_FLOW.html)**

---

## Overview

Phishing attacks remain one of the most prevalent entry points for credential theft and data breaches. Manual detection fails at scale — this project trains ML models on URL structural features to automate classification, following a production-style data pipeline from raw ingestion to evaluated models.

The pipeline runs entirely on a home Ubuntu server, using PostgreSQL as the primary data store and MongoDB to log every model experiment. All analysis is reproducible via four sequential Jupyter notebooks, with R scripts replicating key models for cross-language comparison.

---

## Tech Stack

| Layer | Tools |
|---|---|
| Server | Ubuntu (self-hosted home lab) |
| Relational DB | PostgreSQL 16 |
| Document DB | MongoDB 7.0 |
| Language — ML | Python 3.11 |
| Language — Stats | R 4.3 |
| Python Libraries | pandas · numpy · scikit-learn · matplotlib · seaborn · plotly · sqlalchemy · pymongo |
| R Packages | factoextra · cluster · fpc · randomForest · e1071 · ggplot2 |
| Notebooks | Jupyter |
| Version Control | Git · GitHub |

---

## Repository Structure

```
phishing-ml-detector/
│
├── data/
│   ├── raw/
│   │   └── README.md          # dataset info + download link (CSV not committed)
│   └── clean/                 # cleaned CSV output from Phase 2
│
├── db/
│   ├── schema.sql             # PostgreSQL table definitions
│   ├── queries.sql            # all SQL analysis + audit queries
│   └── mongo_setup.js        # MongoDB collection + index setup
│
├── notebooks/
│   ├── 01_ingest.ipynb        # load raw CSV into PostgreSQL
│   ├── 02_preprocessing.ipynb # Ch. 9 — cleaning pipeline
│   ├── 03_visualization.ipynb # Ch. 4/5 — EDA and charts
│   └── 04_modeling.ipynb      # Ch. 8/11 — classifiers in Python
│
├── r/
│   ├── pca_analysis.R         # PCA with factoextra + scree plot
│   └── classifiers.R          # Random Forest + SVM in R
│
├── visuals/                   # exported chart PNGs for report
│
├── docs/
│   └── PROJECT_FLOW.html      # detailed pipeline walkthrough
│
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Dataset

**CIC Phishing URL Dataset** — Canadian Institute for Cybersecurity

- **Source:** [unb.ca/cic/datasets/url-2016.html](https://www.unb.ca/cic/datasets/url-2016.html)
- **Size:** ~11,000 labeled URL records
- **Labels:** Phishing (1) / Legitimate (0)
- **Features:** URL length, subdomain count, special character count, HTTPS flag, IP-in-URL flag, domain age, URL entropy, digit count, path length

> The raw CSV is not committed to this repo due to file size. See [`data/raw/README.md`](data/raw/README.md) for the download link and placement instructions.

---

## Pipeline

```
Phase 0 → Server + repo setup
Phase 1 → Ingest raw CSV into PostgreSQL
Phase 2 → Preprocess and clean (Chapter 9)
Phase 3 → EDA and visualization (Chapters 4/5)
Phase 4 → Classification in Python and R (Chapters 8 + 11)
Phase 5 → Report and GitHub polish
```

See **[`docs/PROJECT_FLOW.html`](docs/PROJECT_FLOW.html)** for the full phase-by-phase breakdown with code snippets, decision rationale, and interview talking points.

---

## Quickstart

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/phishing-ml-detector.git
cd phishing-ml-detector
```

### 2. Download the dataset

Follow the instructions in [`data/raw/README.md`](data/raw/README.md) to download the CIC dataset and place it at `data/raw/urls.csv`.

### 3. Set up the Python environment

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Configure database credentials

Create a `.env` file in the project root (already in `.gitignore`):

```
POSTGRES_USER=phishuser
POSTGRES_PASSWORD=yourpassword
POSTGRES_DB=phishdb
POSTGRES_HOST=localhost
MONGO_URI=mongodb://localhost:27017/
```

### 5. Initialize the databases

```bash
# PostgreSQL — create tables
psql -U phishuser -d phishdb -f db/schema.sql

# MongoDB — create collections and indexes
mongosh db/mongo_setup.js
```

### 6. Run the notebooks in order

```
notebooks/01_ingest.ipynb
notebooks/02_preprocessing.ipynb
notebooks/03_visualization.ipynb
notebooks/04_modeling.ipynb
```

### 7. Run the R scripts

```bash
Rscript r/pca_analysis.R
Rscript r/classifiers.R
```

---

## Chapters Covered

| Chapter | Topic | Where |
|---|---|---|
| Ch. 4 | Data Visualization | `03_visualization.ipynb` |
| Ch. 5 | Excel in Your Toolkit | Excel charts in `visuals/` |
| Ch. 8 | Python & R Programming | `04_modeling.ipynb` + `r/` |
| Ch. 9 | Data Preprocessing & Cleansing | `02_preprocessing.ipynb` + `db/queries.sql` |
| Ch. 11 | Classification | `04_modeling.ipynb` |

---

## Models Evaluated

Three classifiers are trained and compared across three train/test splits (70/30, 80/20, 90/10). All results are logged to MongoDB for querying.

| Model | Notes |
|---|---|
| Logistic Regression | Linear baseline; interpretable coefficients |
| Random Forest | Handles nonlinear feature interactions; expected top performer |
| Support Vector Machine | Effective in high-dimensional spaces; RBF kernel |

Evaluation metrics: Accuracy · Precision · Recall · F1 Score · Confusion Matrix

---

## Results

> Results table will be populated after notebook runs are complete.

| Model | Split | Accuracy | Precision | Recall | F1 |
|---|---|---|---|---|---|
| Logistic Regression | 80/20 | — | — | — | — |
| Random Forest | 80/20 | — | — | — | — |
| SVM | 80/20 | — | — | — | — |

---

## Author

**Joseph Casperson**
Cybersecurity Major — CS 4200
[LinkedIn](https://linkedin.com/in/joseph-casperson) · [GitHub](https://github.com/joseph-casperson)
