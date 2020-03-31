#!/bin/bash
set -e
BASEDIR="$(realpath "$(dirname "$0")")"
python3 -m venv "$BASEDIR/ipython-env"
. "$BASEDIR/ipython-env/bin/activate"
pip install jupyter notebook
. "$BASEDIR/jupyter-env.sh"
julia meta/install-jupyter.jl
# The IJulia kernel starts up with --project=@., which is not what we
# need, so we delete the option from the kernel invocation.
sed -i -e '/--project=/d' "$JUPYTER_DATA_DIR"/kernels/julia-*/kernel.json
# cd "$(julia gappkgpath.jl)"
# cd JupyterKernel-*
# python3 setup.py install --user

