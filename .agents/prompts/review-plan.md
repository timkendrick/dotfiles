---
description: Launch interactive review UI for a markdown plan file
allowed-tools: Bash(plannotator:*), Bash(jq:*)
---

# Review user-provided plan

Run the following shell command:

```shell
jq --raw-input --slurp '{ tool_input: { plan: . } }' "$1" | plannotator
```

## Your task

The user has reviewed the markdown file and made a `decision` to either `allow` the plan to proceed, or `deny` approval with specific annotations and comments that need to be addressed.
