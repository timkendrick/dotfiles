# Initialize Homebrew environment variables
eval "$(/opt/homebrew/bin/brew shellenv)"

# Ensure Homebrew binaries are located before system binaries
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
