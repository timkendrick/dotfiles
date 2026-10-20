---
name: context-bundle
description: Pack research context into a compact index of file references, and unpack it in one command. Use when the user asks to create or unpack a context bundle, when given a `.context` file, and proactively suggest a bundle before work passes to another agent or session.
---
# Context Bundle

A context bundle is a `.context` file that lists source file slices for an agent to read. It transfers research context from one agent or session to another. The receiving agent runs one command to print every slice, instead of exploring the codebase again turn by turn.

A bundle holds references, not content. The `scripts/bundle` script in this skill directory resolves the references and prints the content.

This document uses these terms:

- Producer: the agent that writes the bundle.
- Consumer: the agent that unpacks the bundle.
- Caller: the party that gives the bundle to the consumer. This can be a user, a parent agent, or the producer itself.

## Format

Each line of a bundle is one of these items:

| Line                                | Meaning                                                        |
| ----------------------------------- | -------------------------------------------------------------- |
| `# @<rev>`                          | Bundle revision pin. Recognized only on line 1. Optional.      |
| `# <text>`                          | Group heading. Optional.                                       |
| `<path>[:N[-M]][:@<rev>] [# note]`  | File reference, with an optional note.                         |
| (blank)                             | Ignored.                                                       |

A file reference has these parts:

- `<path>`: the file path, relative to the project directory. The file must be inside the project directory.
- `:N`: read line N only.
- `:N-M`: read lines N to M.
- No line range: read the whole file.
- `:@<rev>`: read the file at revision `<rev>`. This overrides the bundle pin.
- `# note`: an explanation of why the slice matters. Put whitespace before the `#`.

Revisions resolve in this order:

- The entry revision, if present.
- The bundle pin, if present.
- The working copy.

The revision `@` always means the working copy, in both git and jj. Thus `:@@` reads the file from disk. Any other revision goes to the VCS unchanged, so jj revisions such as `@-` and git revisions such as `HEAD~1` work.

Limits:

- The path ends at the first `:` followed by a digit or `@`.
- Paths and revisions cannot contain whitespace.
- A revision must resolve to exactly one commit.
- Pinned revisions require a VCS. A bundle for files outside a repository must not use pins.

Example:

```
# @3f9c2e1a7b
# Code to modify
src/auth/token.ts:40-85          # refresh flow; keep the retry behavior
src/auth/session.ts:@@           # uncommitted edits from this session
# Patterns to follow
src/billing/invoice-token.ts:12-60
# Tests
test/auth/token.test.ts
```

## Pack a bundle

1. Select a project directory that contains every file that the consumer needs. If some files are outside a package directory, use the repository root.
2. If the project uses a VCS, pin the current commit on line 1:
   - git: use the ID from `git rev-parse HEAD`.
   - jj: use the ID from `jj log -r @ --no-graph -T commit_id`. This command records the working copy first, so the ID includes uncommitted edits.
3. In git, add `:@@` to each entry that refers to uncommitted edits.
4. Add an entry for each slice that the consumer needs:
   - Use line ranges in preference to whole files. Read a whole file only when all of it is relevant.
   - Widen each range to include the complete function, type, or block.
   - Include existing implementations that the consumer must imitate.
   - If the work changes code, include the related tests.
   - Do not add entries that overlap for the same file and revision.
5. Add a note to each entry when its relevance is not obvious. Notes are the best place for small details that are easy to miss.
6. Record context that is not in any file, such as decisions, rejected alternatives, and their reasons:
   - Write it in a document inside the project directory, for example a plan or a notes file.
   - Add the document as the first entry. Use `:@@` if the document is not committed.
   - Do not put this context in the bundle itself. Notes are for details about one slice.
7. Optionally, group the entries under headings.
8. Write the file. If the bundle goes with a document, put it next to the document with the same base name, for example `plan.md` and `plan.context`.
9. Run `scripts/bundle validate <file>`. Correct all errors and do the check again.
10. Give the consumer the full unpack command, and tell it to unpack the bundle first:
    - Use absolute paths for the script and the bundle.
    - Add `--project <dir>` if the paths are not relative to the repository root.
    - Add `--vcs none` if the bundle has no pins and the files are not in a repository.

## Unpack a bundle

1. Before any other exploration, run the unpack command from the caller. Redirect its output to a temporary file, for example `"${TMPDIR:-/tmp}/plan.unpacked.md"`. If you have only the bundle file, run `scripts/bundle unpack <file>` from inside the project.
2. Record the exit status of the unpack command.
3. If the exit status is 1, an entry failed to unpack, and the bundle is incorrect. Do not read the output file. Do not start the task:
   - Run `scripts/bundle validate` with the same options as the unpack command. Its error lines identify the failed entries and their errors.
   - If you can ask the caller a question and wait for the answer, show the error lines. Ask the caller for the missing content or a corrected bundle. Continue only after the caller supplies it.
   - If you cannot ask the caller, stop. Tell the caller that you did not do the task because the bundle is incorrect. Show the error lines.
4. Run `wc -l` on the output file to get its line count N.
5. Read the output file with your file read tool, from line 1:
   - If a read stops before line N, read again from the first line that you did not read.
   - Continue until you read line N. Do not skip any lines.
   - Do not use `grep`, `head`, `tail`, or search tools on the output file in place of a read.
   - Do not start the task until you read line N.
6. Use the output as your primary context.
7. Explore the codebase only for information that the bundle does not supply.
8. When reporting back to the caller, if you had to read project files that the bundle does not reference, write a supplementary bundle for them:
   - Follow the rules in "Pack a bundle".
   - Use the same revision pin as the original bundle. If the original bundle has no pin, do not add one.
   - Write it next to the original bundle, with `.supplement` before the extension. For example, `plan.context` gives `plan.supplement.context`. If you cannot write there, write it to a temporary directory.
   - Run `scripts/bundle validate` on it with the same options as the unpack command.
   - Tell the caller the path of the supplementary bundle.

### Output format

The output is Markdown:

- The first lines show the bundle revision.
- Bundle headings become `##` headings.
- Each entry has a `###` heading with its path and line range. The heading shows a revision only if it is different from the bundle revision.
- The note of the entry follows its heading.
- A fenced block shows the content with the original line numbers.

If an entry fails, the output shows an error in its place. The script continues with the other entries, and the exit status is 1.

## Script reference

```
scripts/bundle unpack [--project <dir>] [--vcs git|jj|none] <bundle-file>
scripts/bundle validate [--project <dir>] [--vcs git|jj|none] <bundle-file>
scripts/bundle --help
```

- Use `-` as `<bundle-file>` to read the bundle from stdin.
- `--project <dir>` sets the directory for bundle paths. It can be a subdirectory of the repository, for example a package in a monorepo.
- Without `--project`, bundle paths are relative to the repository root. If there is no repository, they are relative to the current directory.
- The script searches upward from the project directory for a `.jj` or `.git` directory. jj has priority. Use `--vcs` to override this.
- `--vcs none` reads every file from disk. Every pinned revision is then an error.
- `validate` prints one line per issue, in the form `<file>:<line>: error|warning: <entry>: <message>`. The exit status is 1 if there are errors. These conditions cause a warning only:
  - Entries that overlap for the same file and revision.
  - Slices that contain lines longer than 1000 bytes. Read tools can cut long lines, so the consumer can lose content. Replace these entries, or use narrower ranges that exclude the long lines.
- `validate` then prints a summary on stderr. The first line gives the number of entries, files, and revisions, and the total lines and size of the slices that resolve. The second line gives the number of errors and warnings. Example:

  ```
  12 entries, 9 files, 2 revisions, 1840 lines, 71.3 KB
  0 errors, 1 warning
  ```
- Pinned content always comes from the pinned revision. If a file has no changes since that revision, the script reads it from disk, which is faster.
