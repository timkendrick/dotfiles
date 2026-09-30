load_completions kubectl 'command kubectl completion zsh'

# Global flags that are passed through to the namespace picker so that it queries the same cluster as the command
_KUBECTL_CONNECTION_FLAGS=(
  --as
  --as-group
  --as-uid
  --as-user-extra
  --certificate-authority
  --client-certificate
  --client-key
  --cluster
  --context
  --kubeconfig
  --kuberc
  --server
  --tls-server-name
  --token
  --user
  -s
)

# Top-level subcommands for which a namespace is meaningless
_KUBECTL_NAMESPACELESS_SUBCOMMANDS=(
  api-resources
  api-versions
  cluster-info
  completion
  config
  explain
  help
  kustomize
  options
  plugin
  version
)

# Global flags that consume a value, lazily derived from `kubectl options`
typeset -ga _KUBECTL_GLOBAL_VALUE_FLAGS=()

# Lists all available namespaces in the current Kubernetes context
# Usage: kubectl-list-namespaces [kubectl global flags...]
kubectl-list-namespaces() {
  command kubectl get namespace --output=name "$@" | sed 's/^namespace\///'
}

# Prompts the user to choose a namespace from the list of available namespaces
# Usage: kubectl-select-namespace [kubectl global flags...]
kubectl-select-namespace() {
  local namespaces
  namespaces=$(kubectl-list-namespaces "$@") || return
  fzf --header "Choose a namespace" <<< "$namespaces"
}

# Loads the global options list for kubectl (memoized)
_kubectl_load_global_value_flags() {
  (( ${#_KUBECTL_GLOBAL_VALUE_FLAGS} )) && return
  # Each line of `kubectl options` has the form `    -n, --namespace='':`
  # Flags whose default is not a boolean consume a value
  local line
  while IFS= read -r line; do
    [[ "$line" =~ '^[[:space:]]+(-([[:alnum:]]), )?(--[[:alnum:]-]+)=(.*):$' ]] || continue
    [[ "${match[4]}" == (true|false) ]] && continue
    _KUBECTL_GLOBAL_VALUE_FLAGS+=("${match[3]}")
    [[ -n "${match[2]}" ]] && _KUBECTL_GLOBAL_VALUE_FLAGS+=("-${match[2]}")
  done < <(command kubectl options 2>/dev/null)
}

# Parses the top-level subcommand from the provided kubectl args, skipping any preceding global flags
# Returns the top-level subcommand, or exits with 1 if none is found
# Usage: _kubectl_subcommand <kubectl args...>
_kubectl_subcommand() {
  _kubectl_load_global_value_flags
  while (( $# )); do
    case "$1" in
      --) return 1 ;;
      -*=*) ;;
      -*) (( ${_KUBECTL_GLOBAL_VALUE_FLAGS[(Ie)$1]} )) && shift ;;
      *) echo "$1"; return 0 ;;
    esac
    shift
  done
  return 1
}

# Prints the connection-related global flags found anywhere in the provided kubectl args, one `--flag=value` per line
# Usage: _kubectl_connection_args <kubectl args...>
_kubectl_connection_args() {
  while (( $# )); do
    case "$1" in
      --) break ;;
      --insecure-skip-tls-verify|--insecure-skip-tls-verify=*) print -r -- "$1" ;;
      -*=*) (( ${_KUBECTL_CONNECTION_FLAGS[(Ie)${1%%=*}]} )) && print -r -- "$1" ;;
      -*)
        if (( ${_KUBECTL_CONNECTION_FLAGS[(Ie)$1]} && $# > 1 )); then
          print -r -- "$1=$2"
          shift
        fi
        ;;
    esac
    shift
  done
}

# Determines whether a namespace can potentially be added to the provided kubectl args
# Usage: _kubectl_command_can_accept_namespace <kubectl args...>
_kubectl_command_can_accept_namespace() {
  # Arguments following `--` are passed to the target process (e.g. `kubectl exec pod -- sh`), not kubectl
  local -a args=("$@")
  args=("${(@)args[1,${args[(ie)--]}-1]}")

  # Skip commands that are already namespace-aware, or that only print help
  local arg
  for arg in "${args[@]}"; do
    case "$arg" in
      -h|--help|-n*|--namespace|--namespace=*|-A|--all-namespaces) return 1 ;;
    esac
  done

  local subcommand
  subcommand=$(_kubectl_subcommand "${args[@]}") || return 1
  (( ${_KUBECTL_NAMESPACELESS_SUBCOMMANDS[(Ie)$subcommand]} )) && return 1

  # Ask kubectl which flags the resolved command accepts. This excludes flags already set, and flags of plugins,
  # which cannot be preceded by kubectl flags. Commands that define their own `--namespace` flag
  # (e.g. `kubectl config set-context`) describe it differently from the global flag.
  local line supports_namespace=0 supports_manifests=0
  for line in "${(@f)$(command kubectl __complete "${args[@]}" -- 2>/dev/null)}"; do
    case "$line" in
      $'--namespace\tIf present, the namespace scope for this CLI request'*) supports_namespace=1 ;;
      --filename$'\t'*|--kustomize$'\t'*) supports_manifests=1 ;;
    esac
  done
  (( supports_namespace )) || return 1

  # Leave the namespace of manifest-based commands (e.g. `kubectl apply -f`) to the manifests themselves
  if (( supports_manifests )); then
    for arg in "${args[@]}"; do
      case "$arg" in
        -f*|--filename|--filename=*|-k*|--kustomize|--kustomize=*) return 1 ;;
      esac
    done
  fi

  return 0
}

# Wrapper function for the `kubectl` command that ensures interactive commands specify a namespace.
kubectl() {
  # Require the user to select a namespace if all the following conditions hold:
  # - The command is run within an interactive shell
  # - There are arguments provided
  # - The kubectl subcommand is not a shell completion request
  # - The combination of the kubectl subcommand and provided arguments supports an additional `--namespace` flag
  local -a extra_args=()
  if [[ -t 0 ]] && (( $# )) && [[ "$1" != __complete* ]] && _kubectl_command_can_accept_namespace "$@"; then
    # Extract the provided kubectl arguments that influence the namespace set
    local -a connection_args=(${(f)"$(_kubectl_connection_args "$@")"})
    # Show the namespace selection prompt to the user
    local namespace
    namespace=$(kubectl-select-namespace "${connection_args[@]}") || return
    # If the user did not select a namespace, exit with status 130
    [[ -z "$namespace" ]] && return 130
    extra_args=(--namespace "$namespace")
  fi
  # Prepend the selected namespace (if present) to the kubectl command arguments
  command kubectl "${extra_args[@]}" "$@"
}
