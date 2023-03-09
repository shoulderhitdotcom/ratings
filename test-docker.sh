# docker build -t gcr.io/testing-of-bigquery/testing-julia-job .
# docker push gcr.io/testing-of-bigquery/testing-julia-job
# docker run --rm gcr.io/testing-of-bigquery/testing-julia-job

docker build -t test-julia .
docker run -it --rm test-julia

# docker run -it --rm -p 8080:8080 test-julia
gcloud builds submit -t "gcr.io/testing-of-bigquery/testing-julia-job"

# docker run --rm "gcr.io/testing-of-bigquery/testing-julia-job"

gcloud beta run jobs create job-test-julia \
    --image gcr.io/testing-of-bigquery/testing-julia-job \
    --tasks 1 \
    --max-retries 0 \
    --memory 2Gi\
    --service-account=kifu-depot-scraper-210@testing-of-bigquery.iam.gserviceaccount.com
    #--region australia-southeast2


#gcloud beta run jobs update job-test-julia --memory 2Gi
gcloud beta run jobs update job-test-julia --service-account=kifu-depot-scraper-210@testing-of-bigquery.iam.gserviceaccount.com

gcloud beta run jobs update job-test-julia --max-retries 0


gcloud beta run jobs execute job-test-julia