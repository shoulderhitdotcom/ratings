gcloud iam service-accounts create kifu-depot-scrape \
    --description="A service Account to scrape kifu depot" \
    --display-name="KIFU_DEPOT_SCRAPE"

gcloud projects add-iam-policy-binding testing-of-bigquery \
    --member="serviceAccount:kifu-depot-scrape@testing-of-bigquery.iam.gserviceaccount.com" \
    --role="roles/biqquery.dataEditor"