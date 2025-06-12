FROM continuumio/miniconda3

WORKDIR /pipeline
COPY environment.yml environment.yml
RUN conda env create -f environment.yml

# Activate environment by default
SHELL ["/bin/bash", "-c"]
ENV PATH /opt/conda/envs/fcs_pipeline/bin:$PATH

COPY . /pipeline

RUN mkdir -p data/raw data/processed plots

ENTRYPOINT ["/opt/conda/envs/fcs_pipeline/bin/snakemake"]
CMD ["--help"]
