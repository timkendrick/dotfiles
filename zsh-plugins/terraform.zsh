tf-summary() {
  # Strip ANSI escape sequences
  nocolor |
  # Extract the summary comments (input: "#  <resource> will be <operation>" / "#  <resource> must be <operation>")
  grep '^  # [^(]' | sed -E -e 's/^  # ([^ ]*) (will be|must be) ([^ ]*).*$/\3: \1/' |
  # Format the output
  sed \
    -e 's/^read:/\x1b[1;30m→\x1b[0m/' \
    -e 's/^created:/\x1b[32m+\x1b[0m/' \
    -e 's/^destroyed:/\x1b[31m-\x1b[0m/' \
    -e 's/^updated:/\x1b[33m~\x1b[0m/' \
    -e 's/^replaced:/\x1b[33m↻\x1b[0m/'
}
