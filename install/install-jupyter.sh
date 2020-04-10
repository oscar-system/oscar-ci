#!/bin/bash
set -e
source meta/stdenv.sh
mkdir -p jupyter
python3 -m venv "$JUPYTER_BASE/ipython-env"
source jupyter/ipython-env/bin/activate
pip install --cache-dir "$JUPYTER_BASE/.pip-cache" jupyter notebook
source meta/jupyter-env.sh
julia "meta/install/install-jupyter.jl"
# The IJulia kernel starts up with --project=@., which is not what we
# need, so we delete the option from the kernel invocation.
sed -i -e '/--project=/d' "$JUPYTER_DATA_DIR"/kernels/julia-*/kernel.json
# cd "$(julia gappkgpath.jl)"
# cd JupyterKernel-*
# python3 setup.py install --user

