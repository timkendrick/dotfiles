---
name: rapid-4-implement
description: Interactive workflow for implementing a task that has already been planned. Use only when explicitly requested by the user.
---
# RAPID Workflow Step 4: Implement

Your goal is to implement the task according to the implementation plan.

Implement the task exactly as specified in the implementation plan, including all related tests but excluding documentation.

Focus on correctness, encapsulation, separation of concerns, reuse potential, and maintainability.

Never use type hacks or similar shortcuts, as this incurs non-obvious local technical debt and weakens the codebase.

Pay particular attention to DRY: make sure any repeated conditional logic is extracted into a shared helper function, and that any ad-hoc magic primitives are declared once and exposed as shared constants.

The one scenario where repetition is acceptable is when working with a set of variants of a given interface union: each variant should always be declared in full explicitly and independently of other variants, with source layout and symbol names consistently structured across all variants, even if this results in duplication. In consuming code that handles instances of these interface unions, explicit exhaustive branching is actively encouraged to ensure each variant is handled correctly.

Never include references to the implementation plan or any other documentation in the code itself. Code comments should be used only to explain non-obvious implementation details of the accompanying code and should be entirely self-contained: never include historical notes or comparisons to prior implementations / rejected alternatives in code comments.

Any 'stub' code that needs to be revisited in a later step must have an accompanying `FIXME` comment explaining this.

Make sure to record any deviations from the plan as specified, no matter how trivial. If you encounter any scenarios that require non-trivial deviations or changes to the design, stop and ask the user for guidance on how to proceed.

The output of this session will be a `.agents/plans/*.summary.md` markdown file that contains an implementation summary and a comprehensive listing of all deviations from the plan.
