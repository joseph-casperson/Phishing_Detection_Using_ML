-- =============================================================================
-- queries.sql
-- Phishing Detection ML Project — SQL Analysis Queries (Updated)
-- Author: Joe Casperson
-- =============================================================================
-- HOW TO RUN:
--   Full file:    psql -U phishuser -d phishdb -f db/queries.sql
--   Single query: Copy/paste into psql or pgAdmin
--
-- SECTIONS:
--   1. Data Audit Queries        (Chapter 9 — Preprocessing)
--   2. Exploratory Analysis      (Chapter 6 — SQL in Your Toolset)
--   3. JOIN Demonstrations       (Chapter 6 — Join operations)
--   4. Aggregation & Reporting   (Chapter 6 — Aggregation functions)
--   5. Pre vs Post Clean Compare (Chapter 9 — Verification)
-- =============================================================================


-- =============================================================================
-- SECTION 1 — DATA AUDIT QUERIES
-- Run on the RAW urls table BEFORE cleaning.
-- Screenshot these for the Chapter 9 "Before" section of your report.
-- =============================================================================

-- 1a. Total record count — confirm it matches CSV row count
SELECT COUNT(*) AS total_records
FROM urls;

-- 1b. Class distribution — phishing vs benign
SELECT
    label,
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    COUNT(*)                                               AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)    AS pct
FROM urls
GROUP BY label
ORDER BY label DESC;

-- 1c. NULL counts across key feature columns
SELECT
    COUNT(*) FILTER (WHERE urllen              IS NULL) AS null_urllen,
    COUNT(*) FILTER (WHERE domain_token_count  IS NULL) AS null_domain_tokens,
    COUNT(*) FILTER (WHERE entropy_url         IS NULL) AS null_entropy_url,
    COUNT(*) FILTER (WHERE symbolcount_url     IS NULL) AS null_symbolcount,
    COUNT(*) FILTER (WHERE numberrate_url      IS NULL) AS null_numberrate,
    COUNT(*) FILTER (WHERE label               IS NULL) AS null_label
FROM urls;

-- 1d. Duplicate row count
SELECT COUNT(*) AS duplicate_rows
FROM (
    SELECT urllen, domain_token_count, entropy_url,
           symbolcount_url, label, COUNT(*) AS cnt
    FROM urls
    GROUP BY urllen, domain_token_count, entropy_url,
             symbolcount_url, label
    HAVING COUNT(*) > 1
) AS dupes;

-- 1e. Value range check — spot any impossible or suspicious values
SELECT
    MIN(urllen)             AS min_urllen,
    MAX(urllen)             AS max_urllen,
    MIN(entropy_url)        AS min_entropy,
    MAX(entropy_url)        AS max_entropy,
    MIN(domain_token_count) AS min_domain_tokens,
    MAX(domain_token_count) AS max_domain_tokens,
    MIN(symbolcount_url)    AS min_symbols,
    MAX(symbolcount_url)    AS max_symbols
FROM urls;


-- =============================================================================
-- SECTION 2 — EXPLORATORY ANALYSIS
-- Run on clean_urls AFTER preprocessing.
-- Screenshot for Sections 3 and 4 of your report.
-- =============================================================================

-- 2a. Average feature values by label — the core comparison table
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    ROUND(AVG(urllen),              2) AS avg_url_length,
    ROUND(AVG(domain_token_count),  2) AS avg_domain_tokens,
    ROUND(AVG(entropy_url),         4) AS avg_entropy_url,
    ROUND(AVG(entropy_domain),      4) AS avg_entropy_domain,
    ROUND(AVG(symbolcount_url),     2) AS avg_symbols,
    ROUND(AVG(numberrate_url),      4) AS avg_number_rate,
    ROUND(AVG(numberofdotsinurl),   2) AS avg_dots_in_url,
    ROUND(AVG(path_token_count),    2) AS avg_path_tokens
FROM clean_urls
GROUP BY label
ORDER BY label DESC;

-- 2b. URL length distribution buckets by label
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    CASE
        WHEN urllen < 50  THEN 'Short  (<50)'
        WHEN urllen < 100 THEN 'Medium (50-99)'
        WHEN urllen < 200 THEN 'Long   (100-199)'
        ELSE                   'Very Long (200+)'
    END AS length_bucket,
    COUNT(*) AS count
FROM clean_urls
GROUP BY label, length_bucket
ORDER BY label DESC, length_bucket;

-- 2c. Entropy distribution — high entropy suggests random/obfuscated URLs
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    CASE
        WHEN entropy_url < 2.0 THEN 'Low    (<2.0)'
        WHEN entropy_url < 3.0 THEN 'Medium (2.0-2.9)'
        WHEN entropy_url < 4.0 THEN 'High   (3.0-3.9)'
        ELSE                        'Very High (4.0+)'
    END AS entropy_bucket,
    COUNT(*) AS count
FROM clean_urls
WHERE entropy_url IS NOT NULL
GROUP BY label, entropy_bucket
ORDER BY label DESC, entropy_bucket;

-- 2d. Symbol count comparison — phishing URLs typically have more symbols
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    ROUND(AVG(symbolcount_url),        2) AS avg_url_symbols,
    ROUND(AVG(symbolcount_domain),     2) AS avg_domain_symbols,
    ROUND(AVG(symbolcount_filename),   2) AS avg_filename_symbols,
    ROUND(AVG(symbolcount_afterpath),  2) AS avg_afterpath_symbols
FROM clean_urls
GROUP BY label
ORDER BY label DESC;

-- 2e. Top 10 longest URLs in the phishing class
SELECT
    url_id,
    urllen,
    domain_token_count,
    entropy_url,
    symbolcount_url
FROM clean_urls
WHERE label = 1
ORDER BY urllen DESC
LIMIT 10;


-- =============================================================================
-- SECTION 3 — JOIN DEMONSTRATIONS
-- Required by rubric: illustrate different JOIN types and contrast effects.
-- Both tables (urls, clean_urls) have identical structure — we join them
-- on url_id to compare raw vs clean values for the same records.
-- Screenshot all three outputs and explain the difference in your report.
-- =============================================================================

-- 3a. INNER JOIN — only records that exist in BOTH raw and clean tables
--     Use case: verify which records survived preprocessing unchanged
SELECT
    r.url_id,
    r.label,
    r.urllen        AS raw_urllen,
    c.urllen        AS clean_urllen,
    r.entropy_url   AS raw_entropy,
    c.entropy_url   AS clean_entropy
FROM urls r
INNER JOIN clean_urls c ON r.url_id = c.url_id
LIMIT 10;

-- 3b. LEFT JOIN — all raw records, with clean values where they exist
--     NULLs on the right side = rows that were removed during cleaning
--     Use case: identify exactly which raw rows were dropped and why
SELECT
    r.url_id,
    r.label,
    r.urllen,
    c.url_id        AS clean_id,    -- NULL if row was removed during cleaning
    c.urllen        AS clean_urllen
FROM urls r
LEFT JOIN clean_urls c ON r.url_id = c.url_id
ORDER BY c.url_id NULLS FIRST       -- removed rows appear at the top
LIMIT 15;

-- 3c. Count how many raw rows did NOT survive preprocessing
SELECT COUNT(*) AS rows_removed_by_cleaning
FROM urls r
LEFT JOIN clean_urls c ON r.url_id = c.url_id
WHERE c.url_id IS NULL;

-- 3d. Aggregated JOIN — compare average feature values raw vs clean side by side
--     Shows that cleaning did not significantly skew the distributions
SELECT
    'raw'                              AS dataset,
    ROUND(AVG(urllen),        2)       AS avg_urllen,
    ROUND(AVG(entropy_url),   4)       AS avg_entropy,
    ROUND(AVG(symbolcount_url), 2)     AS avg_symbols,
    COUNT(*)                           AS total_rows
FROM urls
UNION ALL
SELECT
    'clean'                            AS dataset,
    ROUND(AVG(urllen),        2)       AS avg_urllen,
    ROUND(AVG(entropy_url),   4)       AS avg_entropy,
    ROUND(AVG(symbolcount_url), 2)     AS avg_symbols,
    COUNT(*)                           AS total_rows
FROM clean_urls;


-- =============================================================================
-- SECTION 4 — AGGREGATION & REPORTING
-- Uses GROUP BY, HAVING, COUNT, AVG, MAX, MIN, ROUND, window functions.
-- These are the reporting queries — screenshot for Chapter 6 of your report.
-- =============================================================================

-- 4a. Full feature summary statistics by label
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    COUNT(*)                               AS total_records,
    ROUND(AVG(urllen),            1)       AS avg_url_length,
    MAX(urllen)                            AS max_url_length,
    MIN(urllen)                            AS min_url_length,
    ROUND(AVG(entropy_url),       4)       AS avg_entropy,
    ROUND(AVG(domain_token_count),2)       AS avg_domain_tokens,
    ROUND(AVG(symbolcount_url),   2)       AS avg_symbols,
    ROUND(AVG(numberofdotsinurl), 2)       AS avg_dots
FROM clean_urls
GROUP BY label
ORDER BY label DESC;

-- 4b. Domain token count frequency — how complex are phishing domains?
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    domain_token_count,
    COUNT(*) AS frequency
FROM clean_urls
GROUP BY label, domain_token_count
HAVING COUNT(*) > 100
ORDER BY label DESC, domain_token_count;

-- 4c. High-risk profile count
--     URLs with multiple simultaneous phishing indicators
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    COUNT(*) AS high_risk_count
FROM clean_urls
WHERE
    urllen              > 100  AND
    entropy_url         > 3.5  AND
    symbolcount_url     > 10
GROUP BY label
ORDER BY label DESC;

-- 4d. Number rate analysis — ratio of digits in URL components
SELECT
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Benign' END AS label_name,
    ROUND(AVG(numberrate_url),          4) AS avg_numberrate_url,
    ROUND(AVG(numberrate_domain),       4) AS avg_numberrate_domain,
    ROUND(AVG(numberrate_directoryname),4) AS avg_numberrate_dir,
    ROUND(AVG(numberrate_afterpath),    4) AS avg_numberrate_afterpath
FROM clean_urls
GROUP BY label
ORDER BY label DESC;


-- =============================================================================
-- SECTION 5 — PRE vs POST CLEAN COMPARISON
-- Run after notebook 02 completes.
-- Key figures for Chapter 9 — shows cleaning pipeline worked correctly.
-- =============================================================================

-- 5a. Row count before and after
SELECT 'raw'   AS dataset, COUNT(*) AS total_rows FROM urls
UNION ALL
SELECT 'clean' AS dataset, COUNT(*) AS total_rows FROM clean_urls;

-- 5b. Class balance before and after — cleaning must not skew labels
SELECT
    'raw'                                                      AS dataset,
    SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END)                AS phishing_count,
    SUM(CASE WHEN label = 0 THEN 1 ELSE 0 END)                AS benign_count,
    ROUND(AVG(CASE WHEN label = 1 THEN 1.0 ELSE 0.0 END), 4)  AS phishing_rate
FROM urls
UNION ALL
SELECT
    'clean'                                                    AS dataset,
    SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END)                AS phishing_count,
    SUM(CASE WHEN label = 0 THEN 1 ELSE 0 END)                AS benign_count,
    ROUND(AVG(CASE WHEN label = 1 THEN 1.0 ELSE 0.0 END), 4)  AS phishing_rate
FROM clean_urls;

-- 5c. Feature averages before and after — should be nearly identical
SELECT
    'raw'                                AS dataset,
    ROUND(AVG(urllen),          2)       AS avg_urllen,
    ROUND(AVG(entropy_url),     4)       AS avg_entropy,
    ROUND(AVG(symbolcount_url), 2)       AS avg_symbols,
    ROUND(AVG(domain_token_count), 2)    AS avg_domain_tokens
FROM urls
UNION ALL
SELECT
    'clean'                              AS dataset,
    ROUND(AVG(urllen),          2)       AS avg_urllen,
    ROUND(AVG(entropy_url),     4)       AS avg_entropy,
    ROUND(AVG(symbolcount_url), 2)       AS avg_symbols,
    ROUND(AVG(domain_token_count), 2)    AS avg_domain_tokens
FROM clean_urls;
