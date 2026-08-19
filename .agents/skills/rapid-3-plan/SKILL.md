---
name: rapid-3-plan
description: Interactive workflow for planning the implementation of task requirements. Use only when explicitly requested by the user.
---
# RAPID Workflow Step 3: Plan

Your goal is to analyze the task requirements and architectural decisions and collaboratively plan how they will be implemented.

The output of this session will be a `.agents/plans/*.plan.md` markdown file that contains a comprehensive plan that can be executed in isolation from any chat context by a competent junior developer with no knowledge of the project.

The plan is intended to be analyzed in isolation from any chat context and should therefore be standalone and exhaustive. Do not assume any user knowledge, judgement, or decision-making ability, and do not assume any familiarity with the existing codebase.

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

…then once these sections have been written to the markdown file, work section by section with the user, presenting a draft plan for each section to the user for feedback and asking questions for clarification (including suggesting alternatives), appending the fully-drafted section to the document only once the user has approved it:

> ## 4. Technical strategy
> 
> - Clarify surrounding tasks: documentation, testing approach, migrations, deployment, etc
> 
> ## 5. Implementation details
> 
> - Overview of the main implementation steps
> - A subsection for each of the implementation steps. Implementation steps must be incremental; each step should be performed as an isolated atomic commit. Each step should note any checks that need to be performed before proceeding to the next step.
