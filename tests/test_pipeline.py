import subprocess
import os
import shutil
import tempfile


def test_pipeline_runs():
    # locate example file from flowCore
    r_cmd = ["Rscript", "-e", "cat(system.file('extdata','0877408774.B08', package='flowCore'))"]
    res = subprocess.run(r_cmd, capture_output=True, text=True)
    path = res.stdout.strip()
    assert os.path.exists(path)

    temp = tempfile.mkdtemp()
    raw_dir = os.path.join(temp, 'data', 'raw')
    os.makedirs(raw_dir)
    shutil.copy(path, os.path.join(raw_dir, 'sample.fcs'))

    cmd = [
        'snakemake',
        '-s', os.path.join(os.path.dirname(__file__), '..', 'Snakefile'),
        '--directory', temp,
        '--cores', '1'
    ]
    subprocess.check_call(cmd)

    assert os.path.exists(os.path.join(temp, 'data', 'processed', 'sample_umap_clust.fcs'))
    assert os.path.exists(os.path.join(temp, 'plots', 'sample.png'))
