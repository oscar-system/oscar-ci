export JULIA_DEPOT_PATH="${WORKSPACE}/jenv/pkg"
export JULIA_PROJECT="${WORKSPACE}/jenv/proj"
export POLYMAKE_USER_DIR="${WORKSPACE}/.polymake-default"
export PATH="${WORKSPACE}/local/bin:${PATH}"
export JUPYTER_BASE="${WORKSPACE}/jupyter"
export LC_ALL=C
export TERM=dumb
linebuf() {
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL -eL -- "$@"
  elif command -v gstdbuf >/dev/null 2>&1; then
    gstdbuf -oL -eL -- "$@"
  else
    "$@"
  fi
}
