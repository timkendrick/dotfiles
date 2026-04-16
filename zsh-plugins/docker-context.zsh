docker-context() {
    docker-list-context $@ | while read path; do [ -f "$path" ] && echo "'$path'"; done | xargs du -ch
}
