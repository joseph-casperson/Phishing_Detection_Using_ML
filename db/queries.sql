-- =============================================================================
-- queries.sql
-- Phishing Detection ML Project — SQL Analysis Queries
-- =============================================================================
-- HOW TO RUN:
--   Full file:      psql -U phishuser -d phishdb -f db/queries.sql
--   Single query:   Copy/paste into psql or a GUI like DBeaver / pgAdmin
--
-- SECTIONS:
--   1. Data Audit Queries          (Chapter 9 — Preprocessing)
--   2. Exploratory Analysis        (Chapter 6 — SQL in Your Toolset)
--   3. JOIN Demonstrations         (Chapter 6 — Join operations)
--   4. Aggregation & Reporting     (Chapter 6 — Aggregation functions)
--   5. Pre vs Post Clean Compare   (Chapter 9 — Verification)
-- =============================================================================


-- =============================================================================
-- SECTION 1 — DATA AUDIT QUERIES
-- Run these on the RAW tables (urls, features) BEFORE cleaning.
-- Screenshot these results for the Chapter 9 "Before" section of your report.
-- =============================================================================

-- 1a. Total record count — confirm it matches the CSV row count
SELECT COUNT(*) AS total_records
FROM urls;

-- 1b. Class distribution — how many phishing vs. legitimate?
SELECT
    label,
    CASE WHEN label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    COUNT(*)                                                   AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)        AS pct
FROM urls
GROUP BY label
ORDER BY label DESC;

-- 1c. Find exact duplicate URL strings
--     Any url_string appearing more than once is a duplicate.
SELECT
    url_string,
    COUNT(*) AS occurrences
FROM urls
GROUP BY url_string
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- 1d. Count total duplicate rows
SELECT COUNT(*) AS duplicate_count
FROM (
    SELECT url_string
    FROM urls
    GROUP BY url_string
    HAVING COUNT(*) > 1
) AS dupes;

-- 1e. NULL / missing value counts per feature column
SELECT
    COUNT(*) FILTER (WHERE url_length        IS NULL) AS null_url_length,
    COUNT(*) FILTER (WHERE num_subdomains    IS NULL) AS null_num_subdomains,
    COUNT(*) FILTER (WHERE num_special_chars IS NULL) AS null_num_special_chars,
    COUNT(*) FILTER (WHERE https_flag        IS NULL) AS null_https_flag,
    COUNT(*) FILTER (WHERE ip_in_url         IS NULL) AS null_ip_in_url,
    COUNT(*) FILTER (WHERE domain_age_days   IS NULL) AS null_domain_age,
    COUNT(*) FILTER (WHERE url_entropy       IS NULL) AS null_entropy,
    COUNT(*) FILTER (WHERE num_digits        IS NULL) AS null_num_digits,
    COUNT(*) FILTER (WHERE path_length       IS NULL) AS null_path_length
FROM features;

-- 1f. Check for suspicious / out-of-range values
SELECT
    MIN(url_length)        AS min_url_len,
    MAX(url_length)        AS max_url_len,
    MIN(num_subdomains)    AS min_subdomains,
    MAX(num_subdomains)    AS max_subdomains,
    MIN(num_special_chars) AS min_special,
    MAX(num_special_chars) AS max_special,
    MIN(url_entropy)       AS min_entropy,
    MAX(url_entropy)       AS max_entropy
FROM features;


-- =============================================================================
-- SECTION 2 — EXPLORATORY ANALYSIS
-- These queries reveal patterns in the CLEAN data that support your EDA section.
-- Screenshot results and reference them in Sections 3 and 4 of your report.
-- =============================================================================

-- 2a. Average feature values by label — the core comparison
SELECT
    u.label,
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    ROUND(AVG(f.url_length),        2) AS avg_url_length,
    ROUND(AVG(f.num_subdomains),    2) AS avg_subdomains,
    ROUND(AVG(f.num_special_chars), 2) AS avg_special_chars,
    ROUND(AVG(f.url_entropy),       4) AS avg_entropy,
    ROUND(AVG(f.num_digits),        2) AS avg_digits,
    ROUND(AVG(f.path_length),       2) AS avg_path_length
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
GROUP BY u.label
ORDER BY u.label DESC;

-- 2b. HTTPS usage breakdown — what % of each class uses HTTPS?
SELECT
    u.label,
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    SUM(f.https_flag)                                             AS uses_https,
    COUNT(*)                                                      AS total,
    ROUND(SUM(f.https_flag) * 100.0 / COUNT(*), 2)               AS pct_https
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
GROUP BY u.label
ORDER BY u.label DESC;

-- 2c. IP-in-URL breakdown — strong phishing indicator
SELECT
    u.label,
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    SUM(f.ip_in_url)                                              AS uses_ip,
    COUNT(*)                                                      AS total,
    ROUND(SUM(f.ip_in_url) * 100.0 / COUNT(*), 2)                AS pct_ip_in_url
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
GROUP BY u.label
ORDER BY u.label DESC;

-- 2d. URL length distribution buckets — shows how length differs by class
SELECT
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    CASE
        WHEN f.url_length < 30  THEN 'Short  (<30)'
        WHEN f.url_length < 75  THEN 'Medium (30-74)'
        WHEN f.url_length < 150 THEN 'Long   (75-149)'
        ELSE                         'Very Long (150+)'
    END AS length_bucket,
    COUNT(*) AS count
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
GROUP BY u.label, length_bucket
ORDER BY u.label DESC, length_bucket;

-- 2e. Top 10 longest phishing URLs (useful for Excel sort/filter demo)
SELECT
    u.url_string,
    f.url_length,
    f.num_subdomains,
    f.num_special_chars,
    f.https_flag
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
WHERE u.label = 1
ORDER BY f.url_length DESC
LIMIT 10;


-- =============================================================================
-- SECTION 3 — JOIN DEMONSTRATIONS
-- The rubric requires illustrating different JOIN types and contrasting them.
-- These queries use the same base tables but return different result sets.
-- Screenshot all three and explain the difference in your report.
-- =============================================================================

-- 3a. INNER JOIN — only rows that exist in BOTH tables
--     This is the standard query. Every URL that has feature data appears.
--     Use case: analysis where you need complete records only.
SELECT
    u.url_id,
    u.label,
    f.url_length,
    f.num_subdomains,
    f.https_flag
FROM clean_urls u
INNER JOIN clean_features f ON u.url_id = f.url_id
LIMIT 10;

-- 3b. LEFT JOIN — all URLs, even those missing feature rows
--     If a URL was loaded but features were not computed, it still appears
--     with NULL values. Use case: data quality check — spot missing feature rows.
SELECT
    u.url_id,
    u.url_string,
    u.label,
    f.url_length,       -- will be NULL if no matching feature row
    f.num_subdomains
FROM clean_urls u
LEFT JOIN clean_features f ON u.url_id = f.url_id
ORDER BY f.url_length NULLS FIRST  -- NULLs surface first — easy to spot
LIMIT 15;

-- 3c. How many URLs are missing feature rows? (LEFT JOIN anomaly detection)
--     Result should be 0 in a clean dataset. Non-zero = data pipeline issue.
SELECT COUNT(*) AS urls_without_features
FROM clean_urls u
LEFT JOIN clean_features f ON u.url_id = f.url_id
WHERE f.feature_id IS NULL;

-- 3d. SELF JOIN — compare each phishing URL's length against the average
--     phishing URL length. Shows which phishing URLs are abnormally long.
SELECT
    u.url_id,
    f.url_length,
    ROUND(avg_data.avg_len, 2)                    AS avg_phishing_length,
    f.url_length - ROUND(avg_data.avg_len, 2)     AS deviation
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
JOIN (
    SELECT AVG(f2.url_length) AS avg_len
    FROM clean_urls u2
    JOIN clean_features f2 ON u2.url_id = f2.url_id
    WHERE u2.label = 1
) AS avg_data ON TRUE
WHERE u.label = 1
ORDER BY deviation DESC
LIMIT 15;


-- =============================================================================
-- SECTION 4 — AGGREGATION & REPORTING
-- Uses GROUP BY, HAVING, COUNT, AVG, MAX, MIN, ROUND, and window functions.
-- These are the "reporting queries" a data analyst would hand to a manager.
-- =============================================================================

-- 4a. Feature summary statistics by label (full report table)
SELECT
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    COUNT(*)                               AS total_urls,
    ROUND(AVG(f.url_length),    1)         AS avg_length,
    MAX(f.url_length)                      AS max_length,
    MIN(f.url_length)                      AS min_length,
    ROUND(AVG(f.num_subdomains), 2)        AS avg_subdomains,
    ROUND(AVG(f.url_entropy),    4)        AS avg_entropy,
    SUM(f.ip_in_url)                       AS total_ip_in_url,
    SUM(f.https_flag)                      AS total_https
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
GROUP BY u.label
ORDER BY u.label DESC;

-- 4b. Subdomain count frequency — how common is each subdomain count?
SELECT
    u.label,
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    f.num_subdomains,
    COUNT(*) AS frequency
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
GROUP BY u.label, f.num_subdomains
HAVING COUNT(*) > 50           -- only show common counts
ORDER BY u.label DESC, f.num_subdomains;

-- 4c. Entropy percentile buckets — high entropy = more random = more suspicious
SELECT
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    CASE
        WHEN f.url_entropy < 2.0 THEN 'Low    (<2.0)'
        WHEN f.url_entropy < 3.0 THEN 'Medium (2.0-2.9)'
        WHEN f.url_entropy < 4.0 THEN 'High   (3.0-3.9)'
        ELSE                          'Very High (4.0+)'
    END AS entropy_bucket,
    COUNT(*) AS count
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
WHERE f.url_entropy IS NOT NULL
GROUP BY u.label, entropy_bucket
ORDER BY u.label DESC, entropy_bucket;

-- 4d. Dangerous combination count
--     Count URLs that have MULTIPLE phishing indicators simultaneously.
--     (long URL + no HTTPS + IP in URL = very high risk profile)
SELECT
    CASE WHEN u.label = 1 THEN 'Phishing' ELSE 'Legitimate' END AS label_name,
    COUNT(*) AS high_risk_url_count
FROM clean_urls u
JOIN clean_features f ON u.url_id = f.url_id
WHERE
    f.url_length        > 75  AND
    f.https_flag        = 0   AND
    f.num_subdomains    > 2
GROUP BY u.label
ORDER BY u.label DESC;


-- =============================================================================
-- SECTION 5 — PRE vs. POST CLEAN COMPARISON
-- Run these after Phase 2 (preprocessing) is complete.
-- Shows the measurable impact of cleaning — key figure for Chapter 9.
-- =============================================================================

-- 5a. Row count before and after cleaning
SELECT 'raw'   AS dataset, COUNT(*) AS total_rows FROM urls
UNION ALL
SELECT 'clean' AS dataset, COUNT(*) AS total_rows FROM clean_urls;

-- 5b. Class balance before and after — check cleaning didn't skew the labels
SELECT
    'raw'      AS dataset,
    SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) AS phishing_count,
    SUM(CASE WHEN label = 0 THEN 1 ELSE 0 END) AS legitimate_count
FROM urls
UNION ALL
SELECT
    'clean'    AS dataset,
    SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) AS phishing_count,
    SUM(CASE WHEN label = 0 THEN 1 ELSE 0 END) AS legitimate_count
FROM clean_urls;

-- 5c. Feature averages before and after — cleaning should not shift these much
SELECT
    'raw'                                   AS dataset,
    ROUND(AVG(url_length),        2)        AS avg_url_length,
    ROUND(AVG(num_subdomains),    2)        AS avg_subdomains,
    ROUND(AVG(num_special_chars), 2)        AS avg_special_chars
FROM features
UNION ALL
SELECT
    'clean'                                 AS dataset,
    ROUND(AVG(url_length),        2)        AS avg_url_length,
    ROUND(AVG(num_subdomains),    2)        AS avg_subdomains,
    ROUND(AVG(num_special_chars), 2)        AS avg_special_chars
FROM clean_features;
