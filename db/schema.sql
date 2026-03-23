-- =============================================================================
-- schema.sql
-- Phishing Detection ML Project — PostgreSQL Schema (Updated)
-- Author: Joe Casperson
-- =============================================================================
-- HOW TO RUN:
--   psql -U phishuser -d phishdb -f db/schema.sql
--
-- TABLES:
--   urls       → raw data exactly as loaded from Phishing.csv
--   clean_urls → post-preprocessing copy (populated in notebook 02)
--
-- NOTE:
--   The CIC Phishing dataset is fully pre-engineered — there is no raw URL
--   string column. All 79 columns are numeric features. The label column
--   (URL_Type_obf_Type) is encoded as: 1 = phishing, 0 = benign.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 0. CLEAN SLATE
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_urls CASCADE;
DROP TABLE IF EXISTS urls CASCADE;


-- -----------------------------------------------------------------------------
-- 1. urls — raw data table
-- -----------------------------------------------------------------------------
CREATE TABLE urls (
    url_id                         SERIAL PRIMARY KEY,
    label                          SMALLINT NOT NULL CHECK (label IN (0, 1)),
    querylength                    NUMERIC,
    domain_token_count             NUMERIC,
    path_token_count               NUMERIC,
    avgdomaintokenlen              NUMERIC,
    longdomaintokenlen             NUMERIC,
    avgpathtokenlen                NUMERIC,
    tld                            NUMERIC,
    charcompvowels                 NUMERIC,
    charcompace                    NUMERIC,
    ldl_url                        NUMERIC,
    ldl_domain                     NUMERIC,
    ldl_path                       NUMERIC,
    ldl_filename                   NUMERIC,
    ldl_getarg                     NUMERIC,
    dld_url                        NUMERIC,
    dld_domain                     NUMERIC,
    dld_path                       NUMERIC,
    dld_filename                   NUMERIC,
    dld_getarg                     NUMERIC,
    urllen                         NUMERIC,
    domainlength                   NUMERIC,
    pathlength                     NUMERIC,
    subdirlen                      NUMERIC,
    filenamelen                    NUMERIC,
    fileextlen                     NUMERIC,
    arglen                         NUMERIC,
    pathurlratio                   NUMERIC,
    argurlratio                    NUMERIC,
    argdomanratio                  NUMERIC,
    domainurlratio                 NUMERIC,
    pathdomainratio                NUMERIC,
    argpathratio                   NUMERIC,
    executable                     NUMERIC,
    isporteighty                   NUMERIC,
    numberofdotsinurl              NUMERIC,
    isipaddressindomainname        NUMERIC,
    charactercontinuityrate        NUMERIC,
    longestvariablevalue           NUMERIC,
    url_digitcount                 NUMERIC,
    host_digitcount                NUMERIC,
    directory_digitcount           NUMERIC,
    file_name_digitcount           NUMERIC,
    extension_digitcount           NUMERIC,
    query_digitcount               NUMERIC,
    url_letter_count               NUMERIC,
    host_letter_count              NUMERIC,
    directory_lettercount          NUMERIC,
    filename_lettercount           NUMERIC,
    extension_lettercount          NUMERIC,
    query_lettercount              NUMERIC,
    longestpathtokenlength         NUMERIC,
    domain_longestwordlength       NUMERIC,
    path_longestwordlength         NUMERIC,
    subdirectory_longestwordlength NUMERIC,
    arguments_longestwordlength    NUMERIC,
    url_sensitiveword              NUMERIC,
    urlqueries_variable            NUMERIC,
    spcharurl                      NUMERIC,
    delimeter_domain               NUMERIC,
    delimeter_path                 NUMERIC,
    delimeter_count                NUMERIC,
    numberrate_url                 NUMERIC,
    numberrate_domain              NUMERIC,
    numberrate_directoryname       NUMERIC,
    numberrate_filename            NUMERIC,
    numberrate_extension           NUMERIC,
    numberrate_afterpath           NUMERIC,
    symbolcount_url                NUMERIC,
    symbolcount_domain             NUMERIC,
    symbolcount_directoryname      NUMERIC,
    symbolcount_filename           NUMERIC,
    symbolcount_extension          NUMERIC,
    symbolcount_afterpath          NUMERIC,
    entropy_url                    NUMERIC,
    entropy_domain                 NUMERIC,
    entropy_directoryname          NUMERIC,
    entropy_filename               NUMERIC,
    entropy_extension              NUMERIC,
    entropy_afterpath              NUMERIC,
    inserted_at                    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_urls_label   ON urls(label);
CREATE INDEX idx_urls_urllen  ON urls(urllen);
CREATE INDEX idx_urls_entropy ON urls(entropy_url);


-- -----------------------------------------------------------------------------
-- 2. clean_urls — post-preprocessing mirror table
--    Identical structure. Populated by notebook 02.
-- -----------------------------------------------------------------------------
CREATE TABLE clean_urls (
    url_id                         SERIAL PRIMARY KEY,
    label                          SMALLINT NOT NULL CHECK (label IN (0, 1)),
    querylength                    NUMERIC,
    domain_token_count             NUMERIC,
    path_token_count               NUMERIC,
    avgdomaintokenlen              NUMERIC,
    longdomaintokenlen             NUMERIC,
    avgpathtokenlen                NUMERIC,
    tld                            NUMERIC,
    charcompvowels                 NUMERIC,
    charcompace                    NUMERIC,
    ldl_url                        NUMERIC,
    ldl_domain                     NUMERIC,
    ldl_path                       NUMERIC,
    ldl_filename                   NUMERIC,
    ldl_getarg                     NUMERIC,
    dld_url                        NUMERIC,
    dld_domain                     NUMERIC,
    dld_path                       NUMERIC,
    dld_filename                   NUMERIC,
    dld_getarg                     NUMERIC,
    urllen                         NUMERIC,
    domainlength                   NUMERIC,
    pathlength                     NUMERIC,
    subdirlen                      NUMERIC,
    filenamelen                    NUMERIC,
    fileextlen                     NUMERIC,
    arglen                         NUMERIC,
    pathurlratio                   NUMERIC,
    argurlratio                    NUMERIC,
    argdomanratio                  NUMERIC,
    domainurlratio                 NUMERIC,
    pathdomainratio                NUMERIC,
    argpathratio                   NUMERIC,
    executable                     NUMERIC,
    isporteighty                   NUMERIC,
    numberofdotsinurl              NUMERIC,
    isipaddressindomainname        NUMERIC,
    charactercontinuityrate        NUMERIC,
    longestvariablevalue           NUMERIC,
    url_digitcount                 NUMERIC,
    host_digitcount                NUMERIC,
    directory_digitcount           NUMERIC,
    file_name_digitcount           NUMERIC,
    extension_digitcount           NUMERIC,
    query_digitcount               NUMERIC,
    url_letter_count               NUMERIC,
    host_letter_count              NUMERIC,
    directory_lettercount          NUMERIC,
    filename_lettercount           NUMERIC,
    extension_lettercount          NUMERIC,
    query_lettercount              NUMERIC,
    longestpathtokenlength         NUMERIC,
    domain_longestwordlength       NUMERIC,
    path_longestwordlength         NUMERIC,
    subdirectory_longestwordlength NUMERIC,
    arguments_longestwordlength    NUMERIC,
    url_sensitiveword              NUMERIC,
    urlqueries_variable            NUMERIC,
    spcharurl                      NUMERIC,
    delimeter_domain               NUMERIC,
    delimeter_path                 NUMERIC,
    delimeter_count                NUMERIC,
    numberrate_url                 NUMERIC,
    numberrate_domain              NUMERIC,
    numberrate_directoryname       NUMERIC,
    numberrate_filename            NUMERIC,
    numberrate_extension           NUMERIC,
    numberrate_afterpath           NUMERIC,
    symbolcount_url                NUMERIC,
    symbolcount_domain             NUMERIC,
    symbolcount_directoryname      NUMERIC,
    symbolcount_filename           NUMERIC,
    symbolcount_extension          NUMERIC,
    symbolcount_afterpath          NUMERIC,
    entropy_url                    NUMERIC,
    entropy_domain                 NUMERIC,
    entropy_directoryname          NUMERIC,
    entropy_filename               NUMERIC,
    entropy_extension              NUMERIC,
    entropy_afterpath              NUMERIC,
    inserted_at                    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clean_urls_label   ON clean_urls(label);
CREATE INDEX idx_clean_urls_urllen  ON clean_urls(urllen);
CREATE INDEX idx_clean_urls_entropy ON clean_urls(entropy_url);


-- -----------------------------------------------------------------------------
-- 3. VERIFY — should return: clean_urls, urls
-- -----------------------------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
