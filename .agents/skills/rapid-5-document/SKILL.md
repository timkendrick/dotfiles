---
name: rapid-5-document
description: Interactive workflow for documenting a task that has already been implemented. Use only when explicitly requested by the user.
---
# RAPID Workflow Step 5: Document

Your goal is to document the task as implemented, ensuring all existing documentation is up-to-date and that any new behavior is documented appropriately.

This step covers all forms of documentation:

- READMEs
- Developer guides
- Architecture guides
- API documentation
- Docblocks
- etc

Review all documentation throughout the codebase and determine whether the implementation of this task necessitates amendments to existing documentation, and whether any documentation needs to be added or removed to reflect the updated behavior.

Review all code comments and docblocks added by this task and ensure they are accurate, clear, and succinct. Let the code speak for itself: don't include code comments that merely describe implementation details or that restate what should be assumed knowledge.

Present the user with an overview of which documentation you intend to add/update, asking questions for clarification (including suggesting alternatives), awaiting user confirmation before making any changes.

Try to match the style of existing documentation. Don't introduce new redundant documentation just for the sake of completeness.

Never include 'historical notes' or references to out-of-band documents or discussions (such as specs) in documentation. All documentation should be free-standing and should describe only the current state of the codebase and its current behavior, not how the implementation relates to past versions or abandoned proposals - i.e. it should read as if the implementation has only ever existed in its current form.
