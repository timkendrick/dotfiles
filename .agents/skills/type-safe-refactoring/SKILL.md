---
name: type-safe-refactoring
description: Guidance for refactoring TypeScript code involving discriminated unions, exhaustive dispatch, and type-safe construction. Always use when modifying discriminated unions or resolving type errors in union-heavy code.
---

# Type-Safe Refactoring

## Core Principles

### P0: Zero tolerance on type assertions

Never introduce `as T` (except `as const`). If a type assertion feels unavoidable, **stop and ask the user** — there is almost always a structural solution. If one truly cannot be found, isolate the cast inside a single utility function with a `// FIXME: Request user input -` comment, keep every call site type-safe, and surface the FIXME to the user for guidance.

**Why:** Type assertions silence the compiler at the exact point where it is trying to help. Scattering casts across call sites makes it impossible to audit type safety — a single change to the union can silently break every cast without any compiler error.

### P1: Robust type modeling — structs and discriminated unions

Model domain data as explicit **structs** (declared as `interface`) and **discriminated unions** (declared as a `type` alias that is a union of individually declared `interface` variants). Never use anonymous object types, `type` aliases for structs, or untagged unions.

#### Structs

Declare every named object shape as an `interface`:

```typescript
// ✓ CORRECT — named struct declared as interface
export interface Point {
  x: number;
  y: number;
}

// ✗ WRONG — type alias used for a struct
export type Point = { x: number; y: number };
```

#### Discriminated unions

Declare each variant as a standalone `interface` with a `…Type` `enum` `type` discriminant, then combine them into a `type` union:

```typescript
export enum GraphNodeType {
  Leaf = 'leaf',
  Branch = 'branch',
}

export interface LeafGraphNode {
  type: GraphNodeType.Leaf;
  value: number;
}

export interface BranchGraphNode {
  type: GraphNodeType.Branch;
  children: ReadonlyArray<GraphNode>;
}

export type GraphNode = LeafGraphNode | BranchGraphNode;
```

The discriminant field (`type`) must always be an `enum` member, never a raw string literal.

#### Shared base fields — the `…Base` pattern

When all variants share a common set of fields, extract them into a standalone named `…Base` interface and `extend` it in each variant. The `…Base` interface must **not** contain the `type` discriminant — each variant declares its own specific literal:

```typescript
export interface GraphNodeBase {
  id: NodeId;
  label: string;
}

export interface LeafGraphNode extends GraphNodeBase {
  type: GraphNodeType.Leaf;
  value: number;
}

export interface BranchGraphNode extends GraphNodeBase {
  type: GraphNodeType.Branch;
  children: ReadonlyArray<GraphNode>;
}

export type GraphNode = LeafGraphNode | BranchGraphNode;
```

The base can also be generic, which is useful when the shared structure is itself parameterised:

```typescript
export interface EventBase<T> {
  type: T;         // the discriminant type parameter, narrowed per variant
  timestamp: Date;
  correlationId: string;
}

export interface UserCreatedEvent extends EventBase<EventType.UserCreated> {
  userId: string;
  email: string;
}

export interface OrderPlacedEvent extends EventBase<EventType.OrderPlaced> {
  orderId: string;
  total: number;
}

export type DomainEvent = UserCreatedEvent | OrderPlacedEvent;
```

Note that in the generic-base case the discriminant *is* declared on the base — as a type parameter `T` — so each variant still receives its own specific literal when it binds `T` to a concrete enum member.

**Rules summary:**
- Every named object shape → `interface`.
- Every discriminated union → `type` alias over individually declared `interface` variants.
- Every discriminant → an `enum` member, not a raw string literal.
- Shared fields → extracted into a `…Base` interface; `type` discriminant stays on each variant (or is the type parameter in a generic base).
- Do not force a base onto a single-variant type or when variants share no fields.

### P2: Exhaustive `switch`, not chained conditionals

When dispatching on a discriminant, always use an exhaustive `switch` statement terminated by a `default` branch that proves exhaustiveness:

```typescript
default:
  throw input satisfies never;
```

…or if there exists a utility function `function unreachable(x: never): never { throw new TypeError(...); }`:

```typescript
default:
  throw unreachable(input);
```

Replace `if`/`else if` chains that test discriminant values with `switch`. Prefer `switch` inside an IIFE when you need an expression result.

**Why:** Chained conditionals don't provide exhaustiveness checking — adding a new variant to the union produces no compiler error at dispatch sites. An exhaustive `switch` with `satisfies never` causes a compile-time error whenever a new variant is added.

**Note:** Using `.find()` or `.filter()` on a collection to locate a single discriminant type-guarded item is acceptable. It becomes an anti-pattern when you're effectively rebuilding dispatch by repeatedly searching a list for different discriminant values — at that point, replace the list with a `switch`.

### P3: Use `satisfies` to assert the shape of constructed values

When constructing a value of a discriminated union type, use the `satisfies` operator to assert that the object literal matches the intended variant — **do not** rely on a bare type annotation alone, and **never** use `as T`.

```typescript
// ✓ CORRECT — `satisfies` verifies the object matches the specific variant
const circle = {
  kind: ShapeKind.Circle,
  radius: 5,
} satisfies Circle;

// When the variant is determined at runtime, narrow first then apply satisfies
function buildShape(params: ShapeParams): Shape {
  switch (params.kind) {
    case ShapeKind.Circle:
      return { kind: ShapeKind.Circle, radius: params.diameter / 2 } satisfies Circle;
    case ShapeKind.Rectangle:
      return { kind: ShapeKind.Rectangle, width: params.size, height: params.size } satisfies Rectangle;
    default:
      throw params satisfies never;
  }
}
```

`satisfies` checks that the object literal structurally conforms to the named variant *at the point of construction*, giving you an error immediately if a required field is missing or has the wrong type. Unlike a bare type annotation (`const x: Circle = ...`), `satisfies` preserves the literal type of the expression — and unlike `as Circle`, it never silences the compiler.

**Why:** TypeScript cannot prove that a wide union value satisfies any single variant without help. `satisfies` makes each branch's conformance explicit and compiler-verified, and the `switch` narrows the input so each branch is type-safe without casts.

### P4: Construct correctly — don't patch after

Never construct a value with placeholder fields and then spread or overwrite them:

```typescript
// ✗ Anti-pattern: construct then patch
const shape = { kind: ShapeKind.Circle, radius: 5 } satisfies Circle;
const patched: Circle = { ...shape, metadata }; // TypeScript may reject or widen this
```

Instead, include all fields at construction time.

**Why:** Spreading over a discriminated union member can widen the type back to an unresolvable union. TypeScript often rejects the spread or requires a cast to accept it — which leads straight back to violating P0.

---

## Anti-Pattern / Correct-Pattern Pairs

### AP1: Casting anti-patterns

These are casts that substitute for — or paper over the absence of — proper typing. Every example below has a structural fix that makes the cast unnecessary.

#### 1.1 — Cast with an "already-checked" comment

```typescript
// ✗ WRONG — silences the compiler based on an undocumented caller contract
function getRadius(shape: Shape): number {
  return (shape as Circle).radius; // caller guarantees this is a Circle
}
```

```typescript
// ✓ CORRECT — narrow the argument type to what the function actually requires
function getRadius(shape: Circle): number {
  return shape.radius;
}
```

#### 1.2 — Ad-hoc runtime guard instead of a narrow argument type

```typescript
// ✗ WRONG — accepts a wide type, then re-validates structurally at runtime
function getRadius(shape: Shape): number {
  if (!('radius' in shape)) throw new TypeError('Expected a Circle');
  return (shape as Circle).radius;
}
```

```typescript
// ✓ CORRECT — declare the precise type the function requires
function getRadius(shape: Circle): number {
  return shape.radius;
}
```

#### 1.3 — Double assertion to cross an incompatible cast

```typescript
// ✗ WRONG — `as unknown as T` bypasses every structural check
function toCircle(shape: Shape): Circle {
  return shape as unknown as Circle;
}
```

```typescript
// ✓ CORRECT — narrow via switch and construct the target type explicitly
function toCircle(shape: Shape): Circle {
  switch (shape.kind) {
    case ShapeKind.Circle: return shape; // already Circle — no cast needed
    default: throw new TypeError(`Cannot convert ${shape.kind} to Circle`);
  }
}
```

#### 1.4 — Assertion before destructuring a wide union

```typescript
// ✗ WRONG — casts shape to Circle before narrowing, hiding the real problem
function describeCircle(shape: Shape): string {
  const { radius } = shape as Circle;
  return `Circle with radius ${radius}`;
}
```

```typescript
// ✓ CORRECT — narrow first, then destructure
function describeCircle(shape: Shape): string {
  if (shape.kind !== ShapeKind.Circle) throw new TypeError('Expected a Circle');
  const { radius } = shape; // shape is Circle here
  return `Circle with radius ${radius}`;
}
```

#### 1.5 — `Array.find` without a type-guard predicate

```typescript
// ✗ WRONG — isCircle is not a type guard, so the result is widened to Shape,
// and the cast silently drops the `| undefined` case
function findCircle(shapes: Shape[]): Circle {
  return shapes.find(isCircle) as Circle;
}
```

```typescript
// ✓ CORRECT — declare isCircle as a type predicate; handle the undefined case
function isCircle(shape: Shape): shape is Circle {
  return shape.kind === ShapeKind.Circle;
}

function findCircle(shapes: Shape[]): Circle | undefined {
  return shapes.find(isCircle); // inferred as Circle | undefined — no cast needed
}
```

#### 1.6 — Cast stub to satisfy an interface

```typescript
// ✗ WRONG — creates an object that violates the interface at runtime
const node = {} as GraphNode; // "fill in the fields later"
```

```typescript
// ✓ CORRECT — construct with all required fields up front, asserting shape with satisfies (apply P3)
const node = { type: GraphNodeType.Leaf, id: newId(), value: 0 } satisfies LeafGraphNode;
```

### AP2: Chained conditionals instead of exhaustive switch

```typescript
// ✗ WRONG — no exhaustiveness; adding a new Shape variant causes no error here
function area(shape: Shape): number {
  if (shape.kind === 'circle') return Math.PI * shape.radius ** 2;
  if (shape.kind === 'rectangle') return shape.width * shape.height;
  return 0; // silently wrong for any new variant
}
```

```typescript
// ✓ CORRECT — compiler error if a new variant is added
function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':    return Math.PI * shape.radius ** 2;
    case 'rectangle': return shape.width * shape.height;
    default:          throw shape satisfies never;
  }
}
```

For expressions, use an IIFE:

```typescript
const area = (() => {
  switch (shape.kind) {
    case 'circle':    return Math.PI * shape.radius ** 2;
    case 'rectangle': return shape.width * shape.height;
    case 'point':     return null;
    default:          throw shape satisfies never;
  }
})() ?? 0;
```

### AP3: Unnecessary casts

These casts are not needed because TypeScript already has enough information — the programmer either misread what the type checker knows, or forgot that discriminant fields are accessible on unions without casting.

#### 3.1 — Casting a discriminant field via a wider type

```typescript
// ✗ WRONG — TypeScript already resolves `.type` on the union; the cast is noise
function logEvent(event: UserCreatedEvent | OrderPlacedEvent): void {
  console.log((event as DomainEvent).type);
}
```

```typescript
// ✓ CORRECT — access the discriminant directly; no cast required
function logEvent(event: UserCreatedEvent | OrderPlacedEvent): void {
  console.log(event.type);
}
```

#### 3.2 — Casting an already-narrowed value inside a `switch` branch

```typescript
// ✗ WRONG — inside the `circle` branch, `shape` is already Circle
function area(shape: Shape): number {
  switch (shape.kind) {
    case ShapeKind.Circle:    return Math.PI * (shape as Circle).radius ** 2;
    case ShapeKind.Rectangle: return (shape as Rectangle).width * (shape as Rectangle).height;
    default: throw shape satisfies never;
  }
}
```

```typescript
// ✓ CORRECT — the switch branch narrows shape; use it directly
function area(shape: Shape): number {
  switch (shape.kind) {
    case ShapeKind.Circle:    return Math.PI * shape.radius ** 2;
    case ShapeKind.Rectangle: return shape.width * shape.height;
    default: throw shape satisfies never;
  }
}
```

### AP4: Construct-then-spread

```typescript
// ✗ WRONG — spreading `meta` onto a specific variant widens the type
const base = createNode({ id, name, value });
const withOverrides = { ...base, meta: rawMeta };
//                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ type error or requires cast
```

```typescript
// ✓ CORRECT — pass all fields at construction time, using satisfies to verify the shape
function createNode(opts: {
  id: NodeId;
  name: string;
  value: NodeValue;
  meta?: Partial<NodeMeta>;
}): Node {
  return {
    id: opts.id,
    name: opts.name,
    value: opts.value,
    meta: opts.meta ?? {},
  } satisfies Node;
}
```

### AP5: Deferring type safety to comments

```typescript
// ✗ WRONG — planning to verify type safety later is planning to introduce a cast
const node = createNode(definition, { id, name });
// TODO: verify this spread compiles without a cast; if not, flag for review
const nodeWithOverrides: Node = { ...node, overrides };
```

If a construction approach might not compile, **do not write it and hope**. Instead, stop and design an approach that is structurally type-safe (usually by applying P3 — include all fields at construction time and assert the shape with `satisfies`). If you genuinely cannot find a cast-free solution, stop and ask the user for guidance before proceeding.

---

## Pre-Flight Checklist

Before implementing any change that touches a discriminated union:

- [ ] **Identify all construction sites** — every place that creates a value of the union type. These are the sites most likely to break.
- [ ] **Ensure construction sites use `satisfies`** — every object literal that produces a union member should end with `satisfies VariantType` so the compiler verifies the shape at the point of construction.
- [ ] **Grep for `as ` (excluding `as const`)** — any new type assertion is a red flag. Investigate whether a structural solution exists.
- [ ] **Grep for `if.*\.kind ===` / `if.*\.type ===`** — chained discriminant checks should be `switch` statements.
- [ ] **Check `default` branches** — every `switch` on a discriminant must end with `default: throw x satisfies never;` (or return `x satisfies never` in a pure function, but only if the host function's return type is `never`).
- [ ] **Run the type checker** — do not commit until `tsc --noEmit` passes. Do not suppress errors with casts.
