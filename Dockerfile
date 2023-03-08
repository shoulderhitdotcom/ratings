FROM julia:latest

RUN apt-get update -y && \
    apt-get install clang -y

RUN apt-get install apt-transport-https ca-certificates gnupg -y && \
    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-cli -y

ENV JULIA_DEPOT_PATH=/home/.julia

COPY install.jl install.jl

RUN julia install.jl

RUN apt-get install python3 && \
    apt-get install pip -y

# RUN pip install --upgrade google-cloud-bigquery
COPY requirements .

RUN pip install -r requirements

COPY 1-get-bigquery.py .
COPY 2-run-job.jl .
COPY run-job.sh .
RUN alias python="python3"

CMD [ "bash", "run-job.sh" ]
# CMD [ "bash" ]
# ENTRYPOINT [ "bash" ]
# CMD [ "julia", "2-run-job.jl"]
#CMD [ "julia", "-Jtest.so", "run-job.jl"]
