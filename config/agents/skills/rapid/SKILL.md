---
name: rapid
description: Interactive workflow for planning and implementing changes. Use only when explicitly requested by the user.
---
# RAPID Workflow

The RAPID workflow is an interactive sequential workflow for planning and implementing changes. It consists of 5 steps:

1. [Refine](../rapid-1-refine/SKILL.md) – collaboratively refine the task description, fleshing out any areas lacking detail or containing uncertainty into robust, actionable requirements
2. [Architect](../rapid-2-architect/SKILL.md) – analyze the task requirements and collaboratively plan how they will fit in with the existing codebase
3. [Plan](../rapid-3-plan/SKILL.md) – analyze the task requirements and architectural decisions and collaboratively plan how they will be implemented
4. [Implement](../rapid-4-implement/SKILL.md) – implement the task according to the implementation plan
5. [Document](../rapid-5-document/SKILL.md) – document the task as implemented, ensuring all existing documentation is up-to-date and that any new behavior is documented appropriately

Each step is designed to be executed either sequentially within the same chat context, or as a standalone task in isolation from any chat context.

The output of each step is a markdown file in `.agents/plans/*.<step-suffix>.md` whose contents can be referenced by subsequent steps.

IMPORTANT: Always make sure to pause and await user confirmation before proceeding to the next step. The user may request that the output be persisted to a task tracking system as the canonical reference for this document. If this is the case, make sure that subsequent steps reference the canonical version of this document, rather than the `.agents/plans/*.md` draft version.

Once a step has been completed, its output is considered immutable: subsequent steps **must not** modify the output of previous steps.

See the corresponding skill for each step for more details on how to execute that step.
