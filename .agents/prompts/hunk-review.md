---
description: Review changes in a hunk session in a new herdr tab
allowed-tools: Bash(herdr:*), Bash(hunk:*), Bash(tt:*)
---
Load the Hunk review skill (read the file at the path printed by `hunk skill path`).

Open a Hunk review of the changes from <base> to the working copy:

1. Run `hunk session list`. If a session for this repo is already open, reload it with `hunk session reload --repo . -- diff <base> @` and skip to the review.
2. Otherwise, create a focused herdr tab in the current workspace, with its working directory at the repo root:
   herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label "hunk review" --focus
3. Run the diff in the new tab's root pane (the pane_id in the JSON output):
   herdr pane run <pane_id> "hunk diff <base> @"
4. Run `hunk session list` to confirm that the session is connected.

Then annotate the diff:

- Run `hunk session review --repo . --json` to get the file and hunk structure. Read the raw patch only for the files that need it.
- Note all deviations from the plan, as well as any key structural design decisions or potential alternatives.
- Add all notes in one `hunk session comment apply --stdin --focus` batch. Give each note a short summary and potentially additional explanatory content for more complex concepts.
- Notes should act as a high-level code tour for a reviewer who has not seen the code before. Use worked examples, code references and call graphs where appropriate.
- Give me a short summary in the chat as well.
- When I say that I replied, read my replies with `hunk session comment list --repo . --type all --json`. Answer my questions in the session with `--reply-to`. Apply only the changes I approved, then commit and reload the session.

Replace `<base>` with the revision to compare against, for example `main`.

**In a `tt` repository:** use the parent task as the base, and leave out the task archive. The `\$` stops the command substitution from running before `herdr pane run` sends the command to the tab:

```
herdr pane run <pane_id> "hunk diff \$(tt parent) @ -- '~.tt/'"
hunk session reload --repo . -- diff "$(tt parent)" @ -- '~.tt/'
```
