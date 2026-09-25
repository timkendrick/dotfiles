---
name: technical-writing
description: Guidelines and best practices for writing clear and concise technical prose. Always read and follow these guidelines when adding any comments or documentation to your code.
---

## When to Comment

Let the code speak for itself: don't include comments that merely describe implementation details.

Never include 'historical notes' or references to out-of-band documents or discussions (such as specs) in source code comments. These are often irrelevant to the reader, and can become misleading if the code changes.

## When to Document

Consider adding a new Markdown document or section whenever a new core application-domain concept or system architecture component is introduced.

Documents should present a high-level conceptual overview introducing key ideas and principles, followed by more in-depth explanations and worked examples as needed.

Documents can provide pseudocode summaries of algorithms / data pipelines / etc, but should present these as high-level structured explanations. These summaries should describe behavior rather than implementation, and never expose internal implementation details that could change (function names etc).

Documents can include type interfaces where necessary to illustrate key data structures. Type interfaces should be illustrative only: they do not need to be exhaustively specified and should ellide incidental details that are not important to the concept being explained.

Documents should use worked examples to help explain complex concepts.

## Documentation writing style guidelines

Always follow these guidelines when writing code comments and technical documentation:

- use the active voice
- avoid phrasal verbs
- one instruction per sentence
- short, simple sentences (never more than ~20 words)
- use bulleted lists for sequences
- no non-ascii characters
- no em-dashes or other dash separators
- no noun clusters of >3 stacked nouns
- no unnecessary filler words: be direct
- use simple tenses: infinitive, imperative, simple present, simple past, simple future, and past participle as adjective. do not use present perfect and other compound forms.
- no poetic phrasing: rather than "the data is accessed, never cached" just say "the data is not cached."
- always use US English unless explicitly requested by the user.

## Bad Habits Checklist

These six habits cover most of what makes machine-written English hard to parse, and should therefore be avoided:

1. **Synonym rotation** — the same thing gets several names in one document ("the user", "the customer", "the client"). The reader cannot tell whether they are one thing or three. Fix: pick one name, use it every time.
2. **Hedge stacking** — helper verbs and qualifiers pile up until the sentence asserts nothing ("it is important to note that this may potentially help to improve"). Fix: state the claim, or delete it.
3. **Nominalization** — an action frozen into a noun ("perform an analysis of", "provides assistance to"). Fix: use the verb ("analyze", "helps").
4. **Marketing adjectives** — words that claim quality instead of showing it: seamless, robust, powerful, cutting-edge, effortless, blazing-fast. Fix: delete, or replace with the measurement that earns the claim.
5. **Run-on sentences** — several ideas joined by semicolons or em dashes. Fix: one idea per sentence.
6. **Soft phrasal verbs** — spin up, reach out, dive into, kick off. Fix: use the single plain verb (start, contact, read, begin).
