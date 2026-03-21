# Raw Data

The CIC Phishing URL Dataset is not committed to this repository due to file size.

## Download Instructions

1. Visit: https://www.unb.ca/cic/datasets/url-2016.html
2. Download the dataset ZIP file
3. Extract the CSV and rename it to `urls.csv`
4. Place it at `data/raw/urls.csv`

The `01_ingest.ipynb` notebook expects the file at that exact path.

## Dataset Info

- **Name:** CIC Phishing URL Dataset (2016)
- **Source:** Canadian Institute for Cybersecurity, University of New Brunswick
- **Records:** ~11,000 labeled URLs
- **Labels:** 1 = Phishing, 0 = Legitimate
