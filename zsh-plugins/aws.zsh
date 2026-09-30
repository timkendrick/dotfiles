# Activate AWS CLI completions
complete -C "$(which aws_completer)" aws

# Start a new shell with AWS environment variables set
alias aws-session='aws sts get-caller-identity &> /dev/null || aws sso login && env $(aws configure export-credentials --format env-no-export) "$SHELL"'

# Expose AWS environment variables to the prefixed command
# Use with AWS_PROFILE=... environment variable to invoke the command with the specified profile
# Usage: aws-env <command> # AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_SESSION_TOKEN=... <command>
# N.B. Implemented as a function rather than an alias in order to preserve completions for the prefixed command
aws-env() {
    aws sts get-caller-identity &> /dev/null || aws sso login && env $(aws configure export-credentials --format env-no-export) "$@"
}
# For zsh completions, treat the first argument as a command
compdef '_command aws-env' aws-env
