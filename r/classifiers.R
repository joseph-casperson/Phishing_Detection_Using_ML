# =============================================================================
# classifiers.R
# Phishing URL Detection — CS 4200 Final Project
# Author: Joe Casperson
#
# Chapter Coverage: Chapter 8 — Programming Data Mining (Python & R)
#
# Purpose:
#   Replicate Random Forest and SVM classifiers in R at the 80/20 split.
#   Compare results against the Python implementations from notebook 04.
#   Write the Python vs R compare and contrast analysis at the end.
#
# Run: Rscript r/classifiers.R
# =============================================================================

cat("── Loading packages ────────────────────────────\n")

required <- c("randomForest", "e1071", "caret", "ggplot2")
for (pkg in required) {
  library(pkg, character.only = TRUE)
}

cat("✓ Packages loaded\n\n")


# =============================================================================
# 1. Load and prepare data
# =============================================================================
cat("── Loading clean dataset ───────────────────────\n")

df    <- read.csv("data/clean/clean_urls.csv", stringsAsFactors = FALSE)
X_raw <- as.matrix(df[, colnames(df) != "label"])

# Replace Inf/-Inf with NA then median impute
X_raw <- as.data.frame(X_raw)
X_raw[X_raw == Inf | X_raw == -Inf] <- NA
for (col in colnames(X_raw)) {
  if (any(is.na(X_raw[[col]]))) {
    X_raw[[col]][is.na(X_raw[[col]])] <- median(X_raw[[col]], na.rm = TRUE)
  }
}
zero_var_cols <- sapply(X_raw, function(col) var(col, na.rm = TRUE) == 0)
if (any(zero_var_cols)) {
  cat(sprintf("  Removing %d zero-variance columns\n", sum(zero_var_cols)))
  X_raw <- X_raw[, !zero_var_cols]
}
X_raw <- as.matrix(X_raw)
y     <- as.factor(df$label)

# Scale features (equivalent to Python StandardScaler)
X_scaled <- scale(X_raw)

# Apply PCA — retain 90% variance (match Python notebook 04)
pca_result  <- prcomp(X_scaled, scale. = FALSE, center = FALSE)
var_exp     <- pca_result$sdev^2 / sum(pca_result$sdev^2)
n_90        <- which(cumsum(var_exp) >= 0.90)[1]
X_pca       <- pca_result$x[, 1:n_90]

cat(sprintf("✓ Data prepared\n"))
cat(sprintf("  Rows          : %d\n", nrow(X_pca)))
cat(sprintf("  PCA components: %d (90%% variance)\n\n", n_90))


# =============================================================================
# 2. Train / Test Split — 80/20
# =============================================================================
cat("── Splitting data 80/20 ────────────────────────\n")

set.seed(42)
train_idx <- createDataPartition(y, p = 0.80, list = FALSE)
X_train   <- X_pca[train_idx, ]
X_test    <- X_pca[-train_idx, ]
y_train   <- y[train_idx]
y_test    <- y[-train_idx]

cat(sprintf("✓ Train: %d rows  Test: %d rows\n\n",
            nrow(X_train), nrow(X_test)))


# =============================================================================
# Helper: compute and print classification metrics
# =============================================================================
eval_model <- function(model_name, y_true, y_pred) {
  cm        <- confusionMatrix(y_pred, y_true, positive = "1")
  accuracy  <- cm$overall["Accuracy"]
  precision <- cm$byClass["Precision"]
  recall    <- cm$byClass["Recall"]
  f1        <- cm$byClass["F1"]

  cat(sprintf("\n  Model     : %s\n",   model_name))
  cat(sprintf("  Accuracy  : %.4f\n",  accuracy))
  cat(sprintf("  Precision : %.4f\n",  precision))
  cat(sprintf("  Recall    : %.4f\n",  recall))
  cat(sprintf("  F1 Score  : %.4f\n",  f1))
  cat(sprintf("  Confusion Matrix:\n"))
  print(cm$table)

  return(list(
    model     = model_name,
    accuracy  = round(as.numeric(accuracy),  4),
    precision = round(as.numeric(precision), 4),
    recall    = round(as.numeric(recall),    4),
    f1        = round(as.numeric(f1),        4)
  ))
}


# =============================================================================
# 3. Model 1 — Random Forest
# =============================================================================
cat("── Training Random Forest ──────────────────────\n")

set.seed(42)
rf_model <- randomForest(
  x         = X_train,
  y         = y_train,
  ntree     = 100,
  importance= TRUE
)

rf_pred    <- predict(rf_model, X_test)
rf_metrics <- eval_model("Random Forest (R)", y_test, rf_pred)

# Feature importance from RF (PCA components)
cat("\n  Top 5 important PCA components:\n")
imp <- importance(rf_model, type = 2)
imp_sorted <- sort(imp[, 1], decreasing = TRUE)
for (i in 1:5) {
  cat(sprintf("    PC%d: %.4f\n", as.integer(names(imp_sorted)[i]), imp_sorted[i]))
}


# =============================================================================
# 4. Model 2 — Support Vector Machine
# =============================================================================
cat("\n── Training SVM (RBF kernel) ───────────────────\n")
cat("   (this may take 30–60 seconds)\n")

set.seed(42)
svm_model <- svm(
  x       = X_train,
  y       = y_train,
  kernel  = "radial",
  scale   = FALSE      # already scaled
)

svm_pred    <- predict(svm_model, X_test)
svm_metrics <- eval_model("SVM (R)", y_test, svm_pred)


# =============================================================================
# 5. Confusion Matrix Charts
# =============================================================================
cat("\n── Saving confusion matrix charts ──────────────\n")

dir.create("visuals", showWarnings = FALSE)

plot_cm <- function(y_true, y_pred, title, filepath) {
  cm_table <- as.data.frame(table(Predicted = y_pred, Actual = y_true))

  p <- ggplot(cm_table, aes(x = Actual, y = Predicted, fill = Freq)) +
    geom_tile(color = "white", linewidth = 1.2) +
    geom_text(aes(label = Freq), size = 7, fontface = "bold", color = "white") +
    scale_fill_gradient(low = "#bfdbfe", high = "#1d4ed8") +
    scale_x_discrete(labels = c("0" = "Benign", "1" = "Phishing")) +
    scale_y_discrete(labels = c("0" = "Benign", "1" = "Phishing")) +
    labs(title = title, x = "Actual", y = "Predicted") +
    theme_minimal(base_size = 12) +
    theme(
      plot.title  = element_text(face = "bold", hjust = 0.5),
      legend.position = "none",
      panel.grid  = element_blank()
    )

  ggsave(filepath, p, width = 5, height = 4, dpi = 120)
  cat(sprintf("  ✓ Saved: %s\n", filepath))
}

plot_cm(y_test, rf_pred,  "Random Forest — Confusion Matrix (R)",
        "visuals/r_cm_randomforest.png")
plot_cm(y_test, svm_pred, "SVM — Confusion Matrix (R)",
        "visuals/r_cm_svm.png")


# =============================================================================
# 6. R vs Python Results Comparison Table
# =============================================================================
cat("\n── R vs Python Results Comparison ─────────────\n")
cat("  (Fill in Python values from notebook 04 output)\n\n")

comparison <- data.frame(
  Model      = c("Random Forest", "Random Forest", "SVM", "SVM"),
  Language   = c("Python", "R", "Python", "R"),
  Split      = c("80/20", "80/20", "80/20", "80/20"),
  Accuracy   = c(NA, rf_metrics$accuracy,  NA, svm_metrics$accuracy),
  Precision  = c(NA, rf_metrics$precision, NA, svm_metrics$precision),
  Recall     = c(NA, rf_metrics$recall,    NA, svm_metrics$recall),
  F1         = c(NA, rf_metrics$f1,        NA, svm_metrics$f1)
)

print(comparison, row.names = FALSE)
cat("\n  → Fill in Python NA values from notebook 04 master results table.\n")



