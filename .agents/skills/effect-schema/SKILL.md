---
name: effect-schema
description: Conventions for defining Effect Schema types — Struct schemas (product types), Union schemas (sum types), and branded primitive types. Always use when creating or modifying Effect Schema definitions.
---

# Effect Schema Type Modeling

Domain types can be effectively modeled using three fundamental Effect Schema patterns:

1. **Struct** schemas — product types (a fixed set of named fields)
2. **Union** schemas — sum types (a discriminated union of Struct variants)
3. **Branded primitives** — nominal wrappers around `string`, `number`, etc.

Each non-primitive pattern has both a **non-recursive** form and a **recursive** form. Recursive schemas require extra scaffolding to break circular type inference.

---

## General Conventions

### Shared `export const` / `export type` name

Every schema exports a **value** and a **type** under the same name. The value is the `Schema.Struct(…)` / `Schema.Union(…)` definition; the type is the decoded ("Type") side:

```typescript
export const GraphNode = Schema.Struct({ … }).annotations({ identifier: 'GraphNode' });
export type GraphNode = Schema.Schema.Type<typeof GraphNode>;
```

For non-recursive schemas the `type` is declared with a `type` alias. For recursive schemas the `type` is declared with an `interface` (see below).

### Exported `…Schema` type

When a schema participates in a recursive cycle or a Union, also export a `…Schema` type alias that captures both the `Type` and `Encoded` sides:

```typescript
export type GraphNodeSchema = Schema.Schema<GraphNode, GraphNodeEncoded>;
```

This is used as the return-type annotation in `Schema.suspend()` callbacks.

### `identifier` annotations

Every exported schema (and every `Schema.suspend()` call) **must** carry an `identifier` annotation:

- Root schemas: `.annotations({ identifier: 'GraphNode' })` — matches the exported name.
- Suspended schemas: `.annotations({ identifier: 'BranchGraphNode_children' })` — `ParentName_fieldName`.

### Enum discriminants

Use TypeScript `enum` (not `const enum`) for exported discriminant types:

```typescript
export enum GraphNodeType {
  Leaf = 'leaf',
  Branch = 'branch',
}
```

This can be exported as a `Schema.Enums()` schema for use in other schemas

```typescript
export const GraphNodeTypeEnum = Schema.Enums(GraphNodeType).annotations({ identifier: 'GraphNodeType' });
```

> Note the `…Enum` type name suffix to distinguish the schema from the raw TypeScript `enum` value.

Use `Schema.Literal(…)` for the corresponding discriminant field to declare distinct union variants (see below).

---

## Pattern 1: Non-Recursive Struct

The simplest pattern. All fields resolve without circular references.

```typescript
import { Schema } from 'effect';

export const Coordinate = Schema.Struct({
  x: Schema.Number,
  y: Schema.Number,
  label: Schema.NullOr(Schema.String),
}).annotations({ identifier: 'Coordinate' });
export type Coordinate = Schema.Schema.Type<typeof Coordinate>;
```

### Field composition via `…Base.fields`

When multiple structs share a common set of fields, extract a `…Base` schema and spread its `.fields`:

```typescript
const GraphNodeBase = Schema.Struct({
  id: NodeIdFromSelf,
  label: Schema.String,
});
type GraphNodeBase = Schema.Schema.Type<typeof GraphNodeBase>;

export const LeafGraphNode = Schema.Struct({
  ...GraphNodeBase.fields,
  type: Schema.Literal(GraphNodeType.Leaf),
  value: Schema.Number,
}).annotations({ identifier: 'LeafGraphNode' });
export type LeafGraphNode = Schema.Schema.Type<typeof LeafGraphNode>;
```

---

## Pattern 2: Non-Recursive Union

A discriminated union of non-recursive Struct variants. Each variant has a `type` field whose schema is `Schema.Literal(SomeEnum.Variant)`.

```typescript
export enum GraphNodeType {
  Leaf = 'leaf',
  Connector = 'connector',
}

export const LeafGraphNode = Schema.Struct({
  type: Schema.Literal(GraphNodeType.Leaf),
  value: Schema.Number,
}).annotations({ identifier: 'LeafGraphNode' });
export type LeafGraphNode = Schema.Schema.Type<typeof LeafGraphNode>;

export const ConnectorGraphNode = Schema.Struct({
  type: Schema.Literal(GraphNodeType.Connector),
  targetId: NodeIdFromSelf,
}).annotations({ identifier: 'ConnectorGraphNode' });
export type ConnectorGraphNode = Schema.Schema.Type<typeof ConnectorGraphNode>;

export const GraphNode = Schema.Union(
  LeafGraphNode,
  ConnectorGraphNode,
).annotations({ identifier: 'GraphNode' });
export type GraphNode = Schema.Schema.Type<typeof GraphNode>;
```

---

## Pattern 3: Branded Primitive

Branded primitives enforce nominal typing at the type level without changing runtime representation.

### Required: `…FromSelf` (canonical schema)

Every branded primitive **must** define a `…FromSelf` schema using `Schema.declare`. This schema validates that a runtime value already carries the brand — it decodes the branded type *from itself* (no transformation):

```typescript
import { Brand, Schema } from 'effect';

declare const NODE_ID: unique symbol;
export interface NodeIdBrand extends Brand.Brand<typeof NODE_ID> {}
export type NodeId = string & NodeIdBrand;
export const NodeId = Brand.nominal<NodeId>();
export function isNodeId(value: string): value is NodeId {
  return /^[a-z0-9_]+$/.test(value);
}

export const NodeIdFromSelf = Schema.declare(
  (value): value is NodeId => typeof value === 'string' && isNodeId(value),
  {
    identifier: 'NodeId',
  },
).annotations({ jsonSchema: { type: 'string', pattern: '^[a-z0-9_]+$' } });
```

### Optional: `…From…` (decoding schemas)

Additional schemas decode from an unbranded representation and apply the brand:

```typescript
export const NodeIdFromString = Schema.String.pipe(
  Schema.filter(isNodeId),
).pipe(Schema.fromBrand(NodeId));
```

For numeric brands with richer decode/encode needs, use `Schema.transform`:

```typescript
export const TimestampFromDate = Schema.transform(DateFromSelf, TimestampFromSelf, {
  strict: true,
  decode: (date) => Timestamp(date.getTime()),
  encode: (ts) => new Date(ts),
});
```

### Naming convention summary

| Export | Purpose |
|---|---|
| `NodeId` (type) | The branded type (`string & NodeIdBrand`) |
| `NodeId` (value) | The branding function (`Brand.nominal<NodeId>()`) |
| `isNodeId` | Type-guard predicate |
| `NodeIdFromSelf` | Canonical schema — decodes `NodeId` from `NodeId` |
| `NodeIdFromString` | Decodes `NodeId` from `string` |
| `NodeIdFromDate` | Decodes from `Date` (if applicable) |

---

## Recursive Schemas

When a Struct or Union references itself (directly or transitively), TypeScript cannot infer the `Encoded` type because the inference would be circular. The solution has three parts:

1. **Split fields** into `…NonRecursive` and `…Recursive` groups.
2. **Use `Schema.suspend()`** with a return-type annotation for every recursive field.
3. **Declare a named `…Encoded` interface** that breaks the circular inference chain.

Each union variant is either entirely non-recursive or contains recursive fields — there is no mixing within a single field group. All recursive variants follow the same structural template; all non-recursive variants follow the simpler non-recursive template.

### Finding all recursion points

Before writing any code, trace the full recursive structure:

1. Find every `Schema.suspend()` call in the relevant files — each one is a recursion point.
2. For each `Schema.suspend()` call, identify the *parent schema* that contains it (i.e. the schema whose field uses `Schema.suspend()`). That parent schema must use the `NonRecursive`/`Recursive` split + `interface` + `…Encoded` pattern.
3. Also identify the *target schema* referenced inside the `Schema.suspend()` callback. If the target is a union, check every variant whose `…Schema` type appears in a `Schema.suspend()` return-type annotation — those variants are part of the cycle too, even if they are not directly self-referential.
4. Apply the recursive variant pattern to **every** schema that has recursive children via `Schema.suspend()` — not just the ones that TypeScript is currently complaining about. A missed schema anywhere in the cycle will cause the entire structure to collapse.

### Diagnosing circular inference errors

The primary symptom of a schema missing the recursive split is a pair of TypeScript errors:

```
'Foo' implicitly has type 'any' because it does not have a type annotation
  and is referenced directly or indirectly in its own initializer.
Type alias 'Foo' circularly references itself.
```

These errors may appear on *any* schema in the cycle — not necessarily the one that needs to change. Every schema in the cycle that has recursive children via `Schema.suspend()` must be fixed.

Once any schema in the cycle collapses to `any`, downstream schemas that consume it via `Schema.suspend()` will emit spurious secondary errors such as:

```
Types of property 'Context' are incompatible.
  Type 'unknown' is not assignable to type 'never'.
```

These are **not** the root cause. Ignore them and focus exclusively on fixing all `'Foo' implicitly has type 'any'` / `Type alias 'Foo' circularly references itself` errors first. The secondary errors will resolve automatically once all schemas in the cycle are correctly split.

### Recursive Struct

```typescript
const BranchGraphNodeNonRecursive = Schema.Struct({
  type: Schema.Literal(GraphNodeType.Branch),
  label: Schema.String,
});

const BranchGraphNodeRecursive = Schema.Struct({
  children: Schema.Array(
    Schema.suspend((): GraphNodeSchema => GraphNode).annotations({
      identifier: 'BranchGraphNode_children',
    }),
  ),
});

export const BranchGraphNode = Schema.Struct({
  ...BranchGraphNodeNonRecursive.fields,
  ...BranchGraphNodeRecursive.fields,
}).annotations({
  identifier: 'BranchGraphNode',
}) satisfies BranchGraphNodeSchema;

export interface BranchGraphNode
  extends Schema.Schema.Type<typeof BranchGraphNodeNonRecursive>,
    Schema.Schema.Type<typeof BranchGraphNodeRecursive> {}

interface BranchGraphNodeEncoded
  extends Schema.Schema.Encoded<typeof BranchGraphNodeNonRecursive>,
    Schema.Schema.Encoded<typeof BranchGraphNodeRecursive> {}

export type BranchGraphNodeSchema = Schema.Schema<
  BranchGraphNode,
  BranchGraphNodeEncoded
>;
```

Key details:

- The **exported type** is an `interface` that extends both the non-recursive and recursive type helpers — not a `type` alias. This is what breaks the circular inference.
- The `satisfies …Schema` on the schema value proves that the hand-written interfaces are consistent with the actual schema definition.
- The `…NonRecursive`, `…Recursive` and `…Encoded` intermediate schemas/interfaces are **not exported** — they are internal implementation details that only exist to satisfy the type checker.
- The `…NonRecursive` struct must be declared for consistency, even if there are no non-recursive fields (an empty struct is valid).

### Recursive Union

A recursive union combines recursive and non-recursive Struct variants. The root union itself also needs the `…Schema` / `…Encoded` treatment:

```typescript
export const LeafGraphNode = Schema.Struct({
  type: Schema.Literal(GraphNodeType.Leaf),
  value: Schema.Number,
}).annotations({ identifier: 'LeafGraphNode' });
export type LeafGraphNode = Schema.Schema.Type<typeof LeafGraphNode>;
export type LeafGraphNodeSchema = Schema.Schema<
  LeafGraphNode,
  Schema.Schema.Encoded<typeof LeafGraphNode>
>;

export const GraphNode = Schema.Union(
  LeafGraphNode,
  BranchGraphNode,
).annotations({ identifier: 'GraphNode' }) satisfies GraphNodeSchema;

export type GraphNode = LeafGraphNode | BranchGraphNode;

type GraphNodeEncoded =
  | Schema.Schema.Encoded<LeafGraphNodeSchema>
  | Schema.Schema.Encoded<BranchGraphNodeSchema>;

export type GraphNodeSchema = Schema.Schema<GraphNode, GraphNodeEncoded>;
```

The root union schema uses `satisfies GraphNodeSchema` (not a bare assignment) to verify the hand-written type aliases.

### Field-level recursion with shared base fields

When a recursive variant shares base fields with non-recursive variants, the non-recursive base fields go into the `…NonRecursive` struct and the recursive field(s) go into the `…Recursive` struct. The base fields are spread via `.fields`:

```typescript
const BranchGraphNodeNonRecursive = Schema.Struct({
  ...GraphNodeBase.fields,  // shared base
  operator: OperatorEnum,
});

const BranchGraphNodeRecursive = Schema.Struct({
  left: Schema.suspend((): GraphNodeSchema => GraphNode).annotations({
    identifier: 'BranchGraphNode_left',
  }),
  right: Schema.suspend((): GraphNodeSchema => GraphNode).annotations({
    identifier: 'BranchGraphNode_right',
  }),
});
```

### `Schema.suspend()` rules

1. **Always annotate the return type** of the callback: `(): GraphNodeSchema => GraphNode`.
2. **Always add an `identifier` annotation**: `.annotations({ identifier: 'ParentName_fieldName' })`.
3. The return-type annotation references the `…Schema` type alias (which captures both `Type` and `Encoded`), not `typeof SomeSchema`.

---

## Complete Worked Example

A tree structure with leaf nodes (non-recursive) and branch nodes (recursive), where branch nodes contain an array of children:

```typescript
import { Schema } from 'effect';

// ── Discriminant ──────────────────────────────────────────────────────
export enum GraphNodeType {
  Leaf = 'leaf',
  Branch = 'branch',
}

// ── Shared base ───────────────────────────────────────────────────────
const GraphNodeBase = Schema.Struct({
  id: Schema.String,
  label: Schema.String,
});
type GraphNodeBase = Schema.Schema.Type<typeof GraphNodeBase>;

// ── Non-recursive variant ─────────────────────────────────────────────
export const LeafGraphNode = Schema.Struct({
  ...GraphNodeBase.fields,
  type: Schema.Literal(GraphNodeType.Leaf),
  value: Schema.Number,
}).annotations({ identifier: 'LeafGraphNode' });
export type LeafGraphNode = Schema.Schema.Type<typeof LeafGraphNode>;
export type LeafGraphNodeSchema = Schema.Schema<
  LeafGraphNode,
  Schema.Schema.Encoded<typeof LeafGraphNode>
>;

// ── Recursive variant ─────────────────────────────────────────────────
const BranchGraphNodeNonRecursive = Schema.Struct({
  ...GraphNodeBase.fields,
  type: Schema.Literal(GraphNodeType.Branch),
  expanded: Schema.Boolean,
});

const BranchGraphNodeRecursive = Schema.Struct({
  children: Schema.Array(
    Schema.suspend((): GraphNodeSchema => GraphNode).annotations({
      identifier: 'BranchGraphNode_children',
    }),
  ),
});

export interface BranchGraphNode
  extends Schema.Schema.Type<typeof BranchGraphNodeNonRecursive>,
    Schema.Schema.Type<typeof BranchGraphNodeRecursive> {}
interface BranchGraphNodeEncoded
  extends Schema.Schema.Encoded<typeof BranchGraphNodeNonRecursive>,
    Schema.Schema.Encoded<typeof BranchGraphNodeRecursive> {}

export const BranchGraphNode = Schema.Struct({
  ...BranchGraphNodeNonRecursive.fields,
  ...BranchGraphNodeRecursive.fields,
}).annotations({
  identifier: 'BranchGraphNode',
}) satisfies BranchGraphNodeSchema;
export type BranchGraphNodeSchema = Schema.Schema<
  BranchGraphNode,
  BranchGraphNodeEncoded
>;

export const GraphNode = Schema.Union(
  LeafGraphNode,
  BranchGraphNode,
).annotations({ identifier: 'GraphNode' }) satisfies GraphNodeSchema;

export type GraphNode = LeafGraphNode | BranchGraphNode;

type GraphNodeEncoded =
  | Schema.Schema.Encoded<LeafGraphNodeSchema>
  | Schema.Schema.Encoded<BranchGraphNodeSchema>;

export type GraphNodeSchema = Schema.Schema<GraphNode, GraphNodeEncoded>;
```

---

## Quick Reference: Variant Checklists

### Non-recursive variant

- [ ] `export const Foo = Schema.Struct({ … }).annotations({ identifier: 'Foo' })`
- [ ] `export type Foo = Schema.Schema.Type<typeof Foo>`
- [ ] *(If part of a recursive union)* `export type FooSchema = Schema.Schema<Foo, Schema.Schema.Encoded<typeof Foo>>`

### Recursive variant

- [ ] `const FooNonRecursive = Schema.Struct({ … })` *(not exported)*
- [ ] `const FooRecursive = Schema.Struct({ … })` with annotated `Schema.suspend()` fields *(not exported)*
- [ ] `export interface Foo extends Schema.Schema.Type<typeof FooNonRecursive>, Schema.Schema.Type<typeof FooRecursive> {}`
- [ ] `interface FooEncoded extends Schema.Schema.Encoded<typeof FooNonRecursive>, Schema.Schema.Encoded<typeof FooRecursive> {}` *(not exported)*
- [ ] `export const Foo = Schema.Struct({ ...FooNonRecursive.fields, ...FooRecursive.fields }).annotations({ identifier: 'Foo' }) satisfies FooSchema`
- [ ] `export type FooSchema = Schema.Schema<Foo, FooEncoded>`

### Recursive root union

- [ ] `export const RootUnion = Schema.Union(…).annotations({ identifier: 'RootUnion' }) satisfies RootUnionSchema`
- [ ] `export type RootUnion = VariantA | VariantB | …`
- [ ] `type RootUnionEncoded = Schema.Schema.Encoded<VariantASchema> | Schema.Schema.Encoded<VariantBSchema> | …` *(not exported)*
- [ ] `export type RootUnionSchema = Schema.Schema<RootUnion, RootUnionEncoded>`

### Branded primitive

- [ ] `declare const BRAND_SYMBOL: unique symbol`
- [ ] `export interface FooBrand extends Brand.Brand<typeof BRAND_SYMBOL> {}`
- [ ] `export type Foo = <base> & FooBrand` (where `<base>` is `string`, `number`, etc.)
- [ ] `export const Foo = Brand.nominal<Foo>()`
- [ ] `export function isFoo(value: <base>): value is Foo` — type-guard predicate
- [ ] `export const FooFromSelf = Schema.declare(…, { identifier: 'Foo' })` — canonical schema *(required)*
- [ ] `export const FooFromString = …` / `export const FooFromNumber = …` — decoding schemas *(optional)*
