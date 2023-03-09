FROM julia:latest

RUN apt-get update -y && \
    apt-get install clang -y && \
    apt-get install apt-transport-https ca-certificates gnupg -y && \
    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-cli -y && \
    apt-get install python3 && \
    apt-get install pip -y && \
    apt-get install git -y

ENV JULIA_DEPOT_PATH=/home/.julia

# RUN pip install --upgrade google-cloud-bigquery
COPY requirements .

RUN pip install -r requirements

COPY Project.toml .

# ENTRYPOINT [ "julia" ]
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); Pkg.precompile()'

COPY *.py .
COPY *.jl .
COPY run-job.sh .

CMD [ "bash", "run-job.sh" ]
# CMD [ "bash" ]
#  ENTRYPOINT [ "bash" ]
# CMD [ "julia", "--project=.", "2-run-job.jl"]
#CMD [ "julia", "-Jtest.so", "run-job.jl"]
