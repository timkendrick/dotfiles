---
name: jfdi
description: Simple workflow for performing immediate actions without additional planning. Use only when explicitly requested by the user.
---
# JFDI Workflow

The JFDI workflow is a simple non-interactive workflow for enacting requirements that are already well-specified and do not warrant additional planning. It consists of 4 steps:

1. Judge – Assess the clarity of the user intent. If the user intent is clear from the requirements, proceed to step 2. If the requirements are ambiguous, present the user with a set of suggested possible interpretations to help them restate their request clearly. Do not proceed with ambiguous requirements.
2. Flag – present the user with a summary of any actions you are about to take, prominently spotlighting any potential concerns. Ensure the plan summary is presented clearly as a standalone message.
3. Deliver – implement the summarized actions.
4. Inform – present the user with a summary of the actions taken and any necessary deviations that arose while enacting them.
