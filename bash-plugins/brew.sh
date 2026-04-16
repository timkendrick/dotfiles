# Initialize Homebrew environment variables
eval "$(/opt/homebrew/bin/brew shellenv)"

# Ensure Homebrew binaries occur in the PATH before system binaries
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
