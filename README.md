# FCS Analysis Pipeline

This repository contains a Snakemake workflow for analyzing FCS files. For each
input file the pipeline performs the following steps:

1. Selects channels from fcs files based on user input (see Congifuration)
2. Applies an `asinh` transformation with cofactor 5.
3. Computes a 2D UMAP embedding.
4. Performs k-means clustering (5 clusters).
5. Writes a new FCS file containing UMAP coordinates and cluster labels.
6. Generates a UMAP plot coloured by cluster.

The pipeline relies on the `flowCore` R package for parsing FCS files.

# Task:
1) Make it work (build&run) (test on the files in data/raw)
2) Add the possibility to input channels.txt and use only channels with 1 in the last column of channels.txt
3) It is not necessary to fix this repo, feel free to implement the pipeline in 
the language of your choice.
4) The only conditions are:
    - a) it must do what is described above
    - b) It must be runnable in docker container built as part of the install process
    - c) the dependencies must be transparently controled (e.g. via conda environment yaml)
    - d) must run under pipelining tool (e.g. snakemake) which takes care of paralelisation and avoids  recalculations of already processed files.
5) The result must be well documented


# Build and Run pipeline

## Docker

Build a Docker image containing all dependencies:

```bash
docker build -t fcs_pipeline .
```

Run the pipeline using the image:

```bash
# Without config file
docker run --rm -v $(pwd):/pipeline -w /pipeline fcs_pipeline --cores 4

# With config file
docker run --rm -v $(pwd):/pipeline -w /pipeline fcs_pipeline --cores 4 --configfile config.yaml
```

## Conda environment
Create a conda environment and install the dependencies:

```bash
conda env create -f environment.yml
conda activate fcs_pipeline
```

Place your FCS files into `data/raw` (or the directory specified in `raw_dir` in configuration) and run:

```bash
# Without config file (uses defaults)
snakemake --cores 4

# With config file
snakemake --cores 4 --configfile config.yaml
```

Outputs will be written to `data/processed` and `plots`.

# Configuration

The pipeline can be configured using a `config.yaml` file.
The configuration is not necessary, it's possible to run the analysis with default values.

### Data directories
Specify directory with your input data and directories for outputs in `raw_dir`, 
`processed_dir` and `plot_dir` (strings). If not specified following defauls will be used:

```
raw_dir: "data/raw"
processed_dir: "data/processed"
plot_dir: "plots"
```

### Path to channels file

If specified in `channels_file_path` (string) parameter, only channels with "use"=1 in the channels file will be used
If not specified, the pipeline uses all channels with non empty description unless `exclude_pattern` is specified.

Note: all paths should be relative to the root directory.

### Exclude pattern

If no channels file is specified you can exclude channels based on regex pattern in `exclude_pattern` (string) parameter.
If no pattern is provided default `"^FSC|^SSC"` is used.

### Seed

You can specify `seed` (number) to get repeatable results from umap analysis.


## Tests

Unit tests can be executed with `pytest`:

```bash
pytest
```

The tests use an example FCS file distributed with `flowCore` and verify that
the pipeline completes and creates the expected outputs.

## Development

`.devcontainer/devcontainer.json` contain working setup for development environment in vscode. 
What is not working is running interactive debugger with arguments (they are not properly passed as trailing arguments and code change is necessary to make it work) as of now.