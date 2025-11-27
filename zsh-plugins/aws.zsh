# Login to AWS account via SSO and set environment variables
alias aws-session='aws sso login && eval $(aws configure export-credentials --format env)'

# Expose AWS environment variables to the prefixed command
# Use with AWS_PROFILE=... environment variable to invoke the command with the specified profile
# Usage: aws-env <command> # AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_SESSION_TOKEN=... <command>
# N.B. Implemented as a function rather than an alias in order to preserve completions for the prefixed command
aws-env() {
    env $(aws configure export-credentials --format env-no-export | xargs) "$@"
}
# For zsh completions, treat the first argument as a command
compdef '_command aws-env' aws-env
