# Route Parameters & Wildcard Plan

## Current State
- `radix_search` / `linear_search` do **exact string match** only.
- No support for `:param`, `*wildcard`, optional segments, or constraints.

---

## 1. Route Syntax Reference

| Syntax               | Example                | Matches                        | Captures             |
|----------------------|------------------------|--------------------------------|----------------------|
| static               | `/users/list`          | `/users/list`                  | —                    |
| `:param`             | `/users/:id`           | `/users/42`                    | `id = "42"`          |
| `:param?`            | `/users/:id?`          | `/users` or `/users/42`        | `id = "42"` or unset |
| `*`                  | `/files/*`             | `/files/` only                 | —                    |
| `*name`              | `/files/*path`         | `/files/a/b.txt`               | `path = "a/b.txt"`   |
| `:param(regex)`      | `/users/:id(\d+)`      | `/users/42` (not `/users/abc`) | `id = "42"`          |

---

## 2. Segment Types

```c3
enum SegmentType
{
    STATIC,    // exact match: "users"
    PARAM,     // :id — match any single segment, capture
    PARAM_OPT, // :id? — match or skip, capture if present
    WILDCARD,  // *path — match all remaining segments, capture
    GLOB,      // :id(\d+) — match with constraint, capture
}
```

---

## 3. Parsing Routes (in `add()`)

When adding a route, each path segment is classified:

```
/users/:id(\d+)/posts/:slug?
```

1. `users` → `STATIC`
2. `:id(\d+)` → `GLOB` with constraint `\d+`, key `id`
3. `posts` → `STATIC`
4. `:slug?` → `PARAM_OPT`, key `slug`

**Detection rules:**
- Starts with `:` → param variant
  - Contains `(` → `GLOB`, extract constraint between `(` and `)`
  - Ends with `?` → `PARAM_OPT`
  - Otherwise → `PARAM`
- Starts with `*` → `WILDCARD`, key is rest of segment
- Otherwise → `STATIC`

**Node changes:**

```c3
struct Node
{
    String part;        // segment text (without :, *, ?, (regex))
    SegmentType type;
    String key;         // for PARAM/PARAM_OPT/WILDCARD/GLOB — the capture name
    String constraint;  // for GLOB — the raw regex/pattern string
    // ...children, handler, method, has_handler...
}
```

**Constraint string:** For `:id(\d+)`, `part = "id"`, `constraint = "\d+"`.  
Since C3 has no regex in stdlib, matching is done via a simple pattern engine (see §6).

---

## 4. Matching Algorithm

### 4a. Radix Tree Matching

For each request path segment, children are tried **in order**:

1. **STATIC children** — exact match (`segment == child.part`)
2. **First PARAM child** — always matches, captures segment value
3. **First GLOB child** — match if `segment` satisfies constraint, captures value
4. **First PARAM_OPT child** — only tried if the above fail. Captures nothing, skips segment index (does not advance in request).
5. **WILDCARD child** — matches all remaining segments at once. Captures joined suffix with `/`. Must be the last/only child.

No backtracking beyond trying STATIC → PARAM → GLOB → PARAM_OPT → WILDCARD per level.

### 4b. Wildcard Capture

If route is `/files/*path` and request is `/files/a/b/c.txt`:

- Radix navigates: root → `files` → wildcard matches `a/b/c.txt`
- `path = "a/b/c.txt"`

### 4c. Optional Segment Handling

Route `/users/:id?` matches `/users` and `/users/42`:

- **At the optional node:** If there is a next child segment (like `/posts`), try consuming the optional param first; if that fails to match the rest, skip it and try matching the next segment against the optional's siblings.
- This is single-level backtracking at optional boundaries only — NOT full backtracking.

Example: `/a/:b?/c` matching `/a/c`:
1. Match `a` (STATIC)
2. At `:b?` (PARAM_OPT), next expected is `c`. Try consuming "c" as `:b?` value, then look for `c` as sibling — no match.
3. Backtrack: skip `:b?`, try matching `c` against `:b?`'s siblings → match `c` (STATIC). `b` is unset.

### 4d. Linear Search Fallback

Same logic, iterating over flat route list. Each route has pre-parsed segments, and the matcher walks them against the request path with the same STATIC → PARAM → GLOB → PARAM_OPT → WILDCARD priority.

---

## 5. Extracted Params Storage

```c3
const MAX_PARAMS = 16;

struct Param
{
    String key;
    String value;
}

// In Context:
struct Context {
    ...
    Param[MAX_PARAMS] params;
    sz params_count;
}
```

**Accessor:**

```c3
fn String? Context.param(&self, String key)
{
    for (int i = 0; i < (int)self.params_count; i++)
    {
        if (self.params[i].key == key) return self.params[i].value;
    }
    return null;
}
```

Usage in handler:

```c3
fn void user_handler(Context* ctx)
{
    String? id = ctx.param("id");
    response::text(ctx, StatusCode.OK, "User: " + id);
}
```

---

## 6. Constraint / Regex Matching

Since C3's stdlib has no regex, implement a simple **glob-like pattern matcher**:

Supported patterns in constraints:
- `\d+` — one or more digits
- `\w+` — one or more word chars (`[A-Za-z0-9_]`)
- `[a-z]+` — character class (basic range support)
- `.` — any single char
- No grouping, alternation, or quantifiers beyond `+` and `*`

**Implementation:**

```c3
fn bool match_constraint(String segment, String pattern)
{
    // Walk both strings, supporting:
    // \d → check is_digit(c)
    // \w → check is_alnum(c) || c == '_'
    // [abc] or [a-z] → basic char class
    // + → one or more of previous
    // * → zero or more of previous
    // . → any char
}
```

Full PCRE or RE2 support is **not planned** for this phase. The constraint engine is intentionally minimal.

---

## 7. Edge Cases & Behavior

| Route | Request | Matches? | Notes |
|-------|---------|----------|-------|
| `/users/:id` | `/users/` | No | Empty segment doesn't match `:id` |
| `/users/:id?` | `/users` | Yes | Optional omitted |
| `/users/:id?` | `/users/` | No | Trailing slash ≠ omitted |
| `/*` | `/` | Yes | Wildcard matches empty |
| `/*` | `/a/b` | No | `*` matches one segment only (use `*path` for multi) |
| `/a/:p?/b` | `/a/b` | Yes | Optional `:p` skipped |
| `/a/:p?/b` | `/a/x/b` | Yes | Optional `:p` consumed as `x` |
| `/a/:p?/b` | `/a/x/y/b` | No | Too many segments |
| `/a/*path` | `/a` | No | Wildcard needs at least `/` after `/a` |
| `/a/*path` | `/a/` | Yes | `path = ""` |
| `/a/*path` | `/a/b/c` | Yes | `path = "b/c"` |

---

## 8. Implementation Steps

1. **`radix.c3`**: Add `SegmentType` enum, `key`, `constraint` fields to `Node`
2. **`radix.c3`**: Add `match_constraint(segment, pattern)` function
3. **`router.c3`**: Update `add()` to parse `:`, `*`, `?`, `(regex)` from each segment, set node type accordingly
4. **`router.c3`**: Update `radix_search()` with priority-ordered child matching (STATIC → PARAM → GLOB → PARAM_OPT → WILDCARD)
5. **`router.c3`**: Update `linear_search()` with same matching logic
6. **`context.c3`**: Add `Param` struct, `params` array, `params_count`, and `param(key)` accessor
7. **`server.c3`**: Capture param values during route matching and copy into `Context`
8. **`types.c3`**: Add `StatusCode.OK` (done) — also add `StatusCode.BAD_REQUEST` if missing
9. **Test**: Write test routes covering all segment types, optional, wildcards, and constraints in folder tests

---

## 9. Non-Goals (Future)

- Full regex engine (PCRE, RE2)
- Named wildcards in middle of path (`/a/*mid/b` — only trailing `*` is supported)
- Route groups or prefixes (`/api/v1` as a group with relative children)
- Reverse URL generation from route name
- Route middleware / before-filters
