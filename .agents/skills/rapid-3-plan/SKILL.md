---
name: rapid-3-plan
description: Interactive workflow for planning the implementation of task requirements. Use only when explicitly requested by the user.
---
# RAPID Workflow Step 3: Plan

Your goal is to analyze the task requirements and architectural decisions and collaboratively plan how they will be implemented.

The output of this session will be a `.agents/plans/*.plan.md` markdown file that contains a comprehensive plan that can be executed in isolation from any chat context by a competent junior developer with no knowledge of the project.

The plan is intended to be analyzed in isolation from any chat context and should therefore be standalone and exhaustive. The implementor will have access to the output of previous steps, but no further background on the current task.

Do not assume any user knowledge, judgement, or decision-making ability, and do not assume any familiarity with the existing codebase.

Before starting the plan, review the outputs of the previous steps and perform any empirical validation necessary to ensure all implications of the decisions have been considered and that the approach is verifiably feasible.

## Phase 1: Draft the plan

The plan should contain an executive summary, with a high-level description of the task, followed by these 'recap' sections:

> ## 1. Background
> 
> - General context for the task
> 
> ## 2. Research
> 
> - All relevant context and research findings from the conversation so far
> - All paths and identifiers for relevant source code and documentation
> - Other useful context uncovered during research
> - References to any requirement / architecture docs gathered in previous steps
> 
> ## 3. Decision log
> 
> - An overview of the key decisions that will guide implementation

Write sections 1 through 3 to the plan file first. Then draft sections 4 and 5 one section at a time. For each section:

1. Present a summary to the user.
2. Ask for feedback and clarify open questions. Suggest alternatives where useful.
3. Add the full section to the plan file only after the user approves it.

> ## 4. Technical strategy
> 
> - Clarify surrounding tasks: documentation, testing approach, migrations, deployment, etc
> 
> ## 5. Implementation details
> 
> - Overview of the main implementation steps
> - A subsection for each of the implementation steps. Implementation steps must be incremental; each step should be performed as an isolated atomic commit. Each step should note any checks that need to be performed before proceeding to the next step.

## Phase 2: Verify the plan

After drafting the full plan, verify it with a working reference implementation:

1. Spawn a new worker agent in the current codebase. Instruct it to follow the plan exactly, with no additional context. The goal is to test the plan's feasibility as written; do not let the worker invent solutions to circumvent its flaws.
2. Instruct the worker to commit each implementation step separately. It must perform every review gate specified in the plan.
3. If the worker finds a minor error, it must record the deviation, correct it, and continue. Examples include filename typos, wrong line numbers, incorrect build commands, missing diagnostic steps, etc. Additional intermediate commits may be added to implement deviations atomically.
4. If the worker encounters a blocker that prevents it from proceeding with the plan, it must stop and report the blocker to the planning conversation. Follow the blocker process below.
5. If the worker completes all steps of the implementation plan, it must report what it implemented. It must list every inconsistency and deviation and explain how it handled each one.
6. Present the implementation summary to the user. Include an overview of the changes, a tour of the finished code, every deviation from the plan, and how any blockers were resolved.
7. Ask the user to review all inconsistencies. Give the user the opportunity to request changes to the reference implementation or the plan.
8. After the user finishes reviewing, provide the path to the final plan and the VCS commit that contains the completed reference implementation.

### Resolving blockers

If the worker encounters a blocker, follow these steps:

1. The worker must leave the codebase clean before reporting, discarding any uncommitted changes since the most recent successfully-completed step. It must preserve all completed steps and their commits.
2. The worker must report the blocker, the context needed to understand it, and a summary of the partial implementation.
3. Explain the blocker to the user. Include the relevant background and a worked example where useful.
4. Suggest ways to resolve the blocker. Let the user choose an approach or propose another one.
5. Update the plan draft to reflect the chosen approach. Remove obsolete instructions entirely rather than leaving conflicting guidance.
6. Ask the user to confirm before spawning a new worker agent. The new worker must continue the existing partial implementation from the step where the previous worker stopped.
