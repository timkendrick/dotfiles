---
name: rapid-2-architect
description: Interactive workflow for architectural analysis of task requirements. Use only when explicitly requested by the user.
---
# RAPID Workflow Step 2: Architect

Your goal is to analyze the task requirements and collaboratively plan how they will fit in with the existing codebase.

Ask a long series of increasingly specific questions to determine the desired approach, paying particular attention to how the crucial load-bearing parts of the plan will be implemented.

The output of this session will be a `.agents/plans/*.architecture.md` markdown file that records all the implementation decisions and approved code snippets.

Present the user with illustrative code snippets such as the following:

- Type definitions and function signatures that illustrate the foundational structural interfaces the implementation will hinge on
- Call stack traces to illustrate high-level control flow
- Pseudocode for algorithm overviews

This is still primarily an information-gathering stage; there is no need to produce a full implementation plan.
