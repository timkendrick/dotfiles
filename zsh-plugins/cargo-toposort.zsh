# List cargo members in topologically-sorted order
alias 'cargo-toposort'="cargo tree --no-dedupe --prefix depth | grep '^.[:digit:]*[[:alnum:]_-]* v[[:alnum:].-]* ('"$PWD"'[/)]' | sort -r | sed 's/^.[:digit:]*\\([[:alnum:]_-]*\\).*/\\1/' | uniq | awk '!seen[\$0]++'"
