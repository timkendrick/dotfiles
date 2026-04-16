---
name: "review-plan"
description: Use this agent when the user requests a review of a plan file.
tools: Read, Glob, Grep, WebFetch, WebSearch, Edit, Bash(plannotator:*), Bash(jq:*), mcp__context7__query-docs, mcp__context7__resolve-library-id
model: sonnet
---

Run the following shell command and await the result, substituting the path to the plan file for `$1`:

```shell
jq --raw-input --slurp '{ tool_input: { plan: . } }' "$1" | plannotator
```

> **Important:** Do *not* specify a timeout when running this command. The command should be allowed to complete naturally regardless of how long it runs.

Parse the JSON result.

If the `decision` is `deny`, address the annotations and comments, update the plan, and run plannotator again. Repeat until `decision` is `allow`, or the user decides to abandon the plan.

Send the following result, depending on the user's decision:

```
decision: allow
path: /path/to/plan.md
```

```
decision: deny
path: /path/to/plan.md

[summary of feedback for the plan, e.g. "The plan contains a critical design flaw: users do not have the required permissions to execute the proposed solution."]
```
