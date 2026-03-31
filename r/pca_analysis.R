# =============================================================================
# pca_analysis.R
# Phishing URL Detection — CS 4200 Final Project
# Author: Joe Casperson
#
# Chapter Coverage: Chapter 8 — Programming Data Mining (R)
#
# Purpose:
#   Replicate the Python PCA analysis using R's prcomp() and the
#   factoextra package. Produces a scree plot and 2D biplot for
#   comparison against the Python output in notebook 04.
#
# Run: Rscript r/pca_analysis.R
# =============================================================================

cat("── Loading packages ────────────────────────────\n")

# Install packages if not already present
required <- c("factoextra", "ggplot2")
for (pkg in required) {
  library(pkg, character.only = TRUE)
}

cat("✓ Packages loaded\n\n")


# =============================================================================
# 1. Load clean data
# =============================================================================
cat("── Loading clean dataset ───────────────────────\n")

df <- read.csv("data/clean/clean_urls.csv", stringsAsFactors = FALSE)

cat(sprintf("✓ Loaded %d rows × %d columns\n", nrow(df), ncol(df)))
cat(sprintf("  Phishing : %d (%.1f%%)\n",
            sum(df$label == 1), mean(df$label == 1) * 100))
cat(sprintf("  Benign   : %d (%.1f%%)\n\n",
            sum(df$label == 0), mean(df$label == 0) * 100))

# Separate features and labels
X <- df[, colnames(df) != "label"]
# Remove zero-variance and infinite value columns before PCA
X <- as.data.frame(X)

# Replace Inf/-Inf with NA then median impute
X[X == Inf | X == -Inf] <- NA
for (col in colnames(X)) {
  if (any(is.na(X[[col]]))) {
    X[[col]][is.na(X[[col]])] <- median(X[[col]], na.rm = TRUE)
  }
}

# Remove zero-variance columns (prcomp cannot handle these)
zero_var_cols <- sapply(X, function(col) var(col, na.rm = TRUE) == 0)
if (any(zero_var_cols)) {
  cat(sprintf("  Removing %d zero-variance columns: %s\n",
              sum(zero_var_cols),
              paste(names(zero_var_cols)[zero_var_cols], collapse = ", ")))
  X <- X[, !zero_var_cols]
}

X <- as.matrix(X)
y <- as.factor(df$label)


# =============================================================================
# 2. PCA with prcomp (scale. = TRUE applies StandardScaler equivalent)
# =============================================================================
cat("── Running PCA ─────────────────────────────────\n")

pca_result <- prcomp(X, scale. = TRUE, center = TRUE)

# Explained variance
var_explained     <- pca_result$sdev^2 / sum(pca_result$sdev^2)
cumvar            <- cumsum(var_explained)
n_90              <- which(cumvar >= 0.90)[1]
n_95              <- which(cumvar >= 0.95)[1]

cat(sprintf("✓ PCA complete\n"))
cat(sprintf("  Total features             : %d\n", ncol(X)))
cat(sprintf("  Components for 90%% variance: %d\n", n_90))
cat(sprintf("  Components for 95%% variance: %d\n", n_95))
cat(sprintf("  Variance in PC1            : %.2f%%\n", var_explained[1] * 100))
cat(sprintf("  Variance in PC2            : %.2f%%\n\n", var_explained[2] * 100))


# =============================================================================
# 3. Scree Plot
# =============================================================================
cat("── Generating scree plot ───────────────────────\n")

dir.create("visuals", showWarnings = FALSE)

png("visuals/r_pca_scree.png", width = 900, height = 500, res = 120)

p_scree <- fviz_eig(
  pca_result,
  addlabels  = TRUE,
  ncp        = 20,
  barfill    = "#6366f1",
  barcolor   = "#6366f1",
  linecolor  = "#ef4444",
  ggtheme    = theme_minimal(base_size = 11)
) +
  labs(
    title    = "PCA Scree Plot — Variance Explained by Component (R)",
    subtitle = sprintf("Components for 90%% variance: %d  |  95%%: %d", n_90, n_95),
    x        = "Principal Component",
    y        = "Variance Explained (%)"
  ) +
  theme(plot.title = element_text(face = "bold"))

print(p_scree)
dev.off()
cat("✓ Saved: visuals/r_pca_scree.png\n")


# =============================================================================
# 4. PCA Biplot — 2D projection colored by class
# =============================================================================
cat("── Generating PCA biplot ───────────────────────\n")

png("visuals/r_pca_biplot.png", width = 900, height = 700, res = 120)

p_biplot <- fviz_pca_ind(
  pca_result,
  geom.ind     = "point",
  col.ind      = y,
  palette      = c("#3b82f6", "#ef4444"),
  addEllipses  = TRUE,
  ellipse.type = "convex",
  legend.title = "Class",
  alpha.ind    = 0.4,
  pointsize    = 1.2,
  ggtheme      = theme_minimal(base_size = 11)
) +
  labs(
    title    = "PCA — 2D Projection by Class (R)",
    subtitle = sprintf(
      "PC1: %.1f%%  PC2: %.1f%%  Total: %.1f%%",
      var_explained[1] * 100,
      var_explained[2] * 100,
      (var_explained[1] + var_explained[2]) * 100
    )
  ) +
  scale_color_manual(values = c("0" = "#3b82f6", "1" = "#ef4444"),
                     labels = c("0" = "Benign", "1" = "Phishing")) +
  scale_fill_manual(values  = c("0" = "#3b82f6", "1" = "#ef4444"),
                    labels  = c("0" = "Benign", "1" = "Phishing")) +
  theme(plot.title = element_text(face = "bold"))

print(p_biplot)
dev.off()
cat("✓ Saved: visuals/r_pca_biplot.png\n\n")


# =============================================================================
# 5. Summary comparison with Python
# =============================================================================
cat("── R vs Python PCA Comparison ──────────────────\n")
cat(sprintf("  Components for 90%% variance  R: %d\n", n_90))
cat("  Components for 90%% variance  Python: (check notebook 04 output)\n")
cat("  → Both should be identical since the same scaling and algorithm are used.\n\n")

cat("── Top 5 Variable Contributions to PC1 ────────\n")
loadings_pc1 <- sort(abs(pca_result$rotation[, 1]), decreasing = TRUE)
for (i in 1:5) {
  cat(sprintf("  %s: %.4f\n", names(loadings_pc1)[i], loadings_pc1[i]))
}

cat("\n✓ pca_analysis.R complete\n")
