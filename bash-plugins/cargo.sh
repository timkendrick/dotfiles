# Load the cargo environment, if rustup has installed it
CARGO_ENV_PATH="${CARGO_HOME:-$HOME/.cargo}/env"
[[ -f "$CARGO_ENV_PATH" ]] && . "$CARGO_ENV_PATH"
unset CARGO_ENV_PATH
