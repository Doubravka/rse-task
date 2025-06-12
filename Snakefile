import os, glob
RAW_DIR = config.get('raw_dir', 'data/raw')
PROCESSED_DIR = config.get('processed_dir', 'data/processed')
PLOT_DIR = config.get('plot_dir', 'plots')

samples = [os.path.splitext(os.path.basename(f))[0] for f in glob.glob(os.path.join(RAW_DIR, '*.fcs'))]

rule all:
    input:
        expand(os.path.join(PROCESSED_DIR, '{sample}_umap_clust.fcs'), sample=samples),
        expand(os.path.join(PLOT_DIR, '{sample}.png'), sample=samples)

rule process_fcs:
    input:
        os.path.join(RAW_DIR, '{sample}.fcs')
    output:
        fcs=os.path.join(PROCESSED_DIR, '{sample}_umap_clust.fcs'),
        plot=os.path.join(PLOT_DIR, '{sample}.png')
    shell:
        'Rscript {workflow.basedir}/scripts/process_fcs.R -i {input} -o {output.fcs} -p {output.plot}'
