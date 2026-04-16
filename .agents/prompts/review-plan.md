---
description: Launch interactive review UI for a markdown plan file
allowed-tools: Bash(plannotator:*), Bash(jq:*)
---

# Review user-provided plan

Run the following shell command and await the result:

```shell
jq --raw-input --slurp '{ tool_input: { plan: . } }' "$1" | plannotator
```

> **Important:** Do *not* specify a timeout when running this command. The command should be allowed to complete naturally regardless of how long it runs.

## Your task

The user has reviewed the markdown file and made a `decision` to either `allow` the plan to proceed, or `deny` approval with specific annotations and comments that need to be addressed.

For each item of feedback, clarify a summary of proposed amendments that would address the feedback, confirming the amendments the user via your `ask` tool.

Once the user has approved the amendments, apply the amendments via surgical edits to the user-provided plan and resubmit for review.
