-- =============================================================================
-- schema.sql
-- Phishing Detection ML Project — PostgreSQL Schema
-- =============================================================================
-- HOW TO RUN:
--   psql -U phishuser -d phishdb -f db/schema.sql
--
-- TABLES:
--   urls          → one row per URL string with its ground-truth label
--   features      → one row per URL with all engineered numeric features
--   clean_urls    → post-preprocessing copy of urls (populated in Phase 2)
--   clean_features→ post-preprocessing copy of features (populated in Phase 2)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 0. CLEAN SLATE
--    Drop tables in reverse dependency order (features before urls)
--    so re-running this script is safe during development
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_features;
DROP TABLE IF EXISTS clean_urls;
DROP TABLE IF EXISTS features;
DROP TABLE IF EXISTS urls;


-- -----------------------------------------------------------------------------
-- 1. urls
--    Stores the raw URL string and its binary classification label.
--    This is the "parent" table — features references it via url_id.
-- -----------------------------------------------------------------------------
CREATE TABLE urls (
    url_id      SERIAL PRIMARY KEY,         -- auto-incrementing unique ID
    url_string  TEXT        NOT NULL,       -- the raw URL (e.g. http://evil.xyz/login)
    label       SMALLINT    NOT NULL        -- 1 = phishing, 0 = legitimate
                CHECK (label IN (0, 1)),
    inserted_at TIMESTAMPTZ DEFAULT NOW()   -- when this row was loaded
);

-- Index on label for fast GROUP BY / WHERE label = 1 queries
CREATE INDEX idx_urls_label ON urls(label);


-- -----------------------------------------------------------------------------
-- 2. features
--    Stores all engineered numeric features for each URL.
--    Foreign key → urls.url_id (one-to-one relationship).
--
--    Feature descriptions:
--      url_length        → total character count of the URL string
--      num_subdomains    → count of dot-separated subdomain segments
--      num_special_chars → count of special chars (@, -, _, %, =, ?)
--      https_flag        → 1 if URL starts with https://, else 0
--      ip_in_url         → 1 if an IP address appears instead of a domain
--      domain_age_days   → age of the domain in days (-1 if unknown)
--      url_entropy       → Shannon entropy of the URL string (randomness score)
--      num_digits        → count of digit characters in the URL
--      path_length       → character count of the URL path component only
-- -----------------------------------------------------------------------------
CREATE TABLE features (
    feature_id        SERIAL PRIMARY KEY,
    url_id            INTEGER     NOT NULL REFERENCES urls(url_id) ON DELETE CASCADE,

    url_length        INTEGER     NOT NULL CHECK (url_length >= 0),
    num_subdomains    INTEGER     NOT NULL CHECK (num_subdomains >= 0),
    num_special_chars INTEGER     NOT NULL CHECK (num_special_chars >= 0),
    https_flag        SMALLINT    NOT NULL CHECK (https_flag IN (0, 1)),
    ip_in_url         SMALLINT    NOT NULL CHECK (ip_in_url IN (0, 1)),
    domain_age_days   INTEGER     NOT NULL DEFAULT -1,  -- -1 = unknown/not available
    url_entropy       NUMERIC(6,4),                     -- e.g. 3.8412
    num_digits        INTEGER     NOT NULL DEFAULT 0 CHECK (num_digits >= 0),
    path_length       INTEGER     NOT NULL DEFAULT 0 CHECK (path_length >= 0)
);

-- Index on url_id for fast JOIN performance
CREATE INDEX idx_features_url_id ON features(url_id);


-- -----------------------------------------------------------------------------
-- 3. clean_urls / clean_features
--    Mirror tables populated during Phase 2 (preprocessing).
--    Keeping raw and clean data in separate tables lets you compare them
--    with SQL queries and proves the cleaning pipeline worked.
-- -----------------------------------------------------------------------------
CREATE TABLE clean_urls (
    url_id      SERIAL PRIMARY KEY,
    url_string  TEXT        NOT NULL,
    label       SMALLINT    NOT NULL CHECK (label IN (0, 1)),
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clean_urls_label ON clean_urls(label);

CREATE TABLE clean_features (
    feature_id        SERIAL PRIMARY KEY,
    url_id            INTEGER     NOT NULL REFERENCES clean_urls(url_id) ON DELETE CASCADE,

    url_length        INTEGER     NOT NULL CHECK (url_length >= 0),
    num_subdomains    INTEGER     NOT NULL CHECK (num_subdomains >= 0),
    num_special_chars INTEGER     NOT NULL CHECK (num_special_chars >= 0),
    https_flag        SMALLINT    NOT NULL CHECK (https_flag IN (0, 1)),
    ip_in_url         SMALLINT    NOT NULL CHECK (ip_in_url IN (0, 1)),
    domain_age_days   INTEGER     NOT NULL DEFAULT -1,
    url_entropy       NUMERIC(6,4),
    num_digits        INTEGER     NOT NULL DEFAULT 0 CHECK (num_digits >= 0),
    path_length       INTEGER     NOT NULL DEFAULT 0 CHECK (path_length >= 0)
);

CREATE INDEX idx_clean_features_url_id ON clean_features(url_id);


-- -----------------------------------------------------------------------------
-- 4. VERIFY
--    After running this file, this query should return all 4 table names.
-- -----------------------------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
