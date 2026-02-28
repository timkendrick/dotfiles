# Run a command repeatedly, refreshing the screen after each execution
# Usage: liveexec <command> [args...]
# Example: liveexec sh -c 'echo "Current time: $(date)"'
liveexec() {
    # Check if a command was provided
    if [ $# -eq 0 ]; then
        echo "Usage: liveexec <command> [args...]" >&2
        return 1
    fi

    # Trap Ctrl+C to exit gracefully and restore cursor settings
    trap 'stty echo; echo; return' INT

    while true; do
        clear
        # Execute the passed command with all its arguments
        "$@"

        # -k 1: read 1 keypress
        # -s: silent mode (don't echo the character to the screen)
        # -r: raw mode (don't treat backslashes as escape chars)
        read -rs -k 1

        if [[ "$REPLY" == "q" || "$REPLY" == "Q" ]]; then
            clear
            break
        fi
    done
}
