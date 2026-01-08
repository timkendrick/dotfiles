nocolor() {
  # Strip ANSI escape sequences
  sed -e 's/\x1b\[[0-9;]*m//g'
}
