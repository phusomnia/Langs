# NestC3

A lightweight web framework written in C3 with HTTP routing, request handling, and logging capabilities.

## Features

- HTTP server supporting GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS methods
- Radix tree-based router with linear search fallback
- Parameter extraction with optional parameters and regex constraints
- Colored logging system (info, warn, error, success, debug)
- Clean modular architecture

## Folder Structure

```
NestC3/
├── src/
│   ├── core/       # Core application logic (app, context, logger, server, socket)
│   ├── http/       # HTTP types and handlers (types, response, request, parser)
│   ├── router/     # Routing implementation (router, route, radix)
│   ├── tests/      # Test files
│   └── main.c3     # Entry point with example routes
├── build/          # Build output directory
├── docs/           # Documentation
├── resources/      # Static resources
└── build.sh        # Build script using c3c compiler
```

## Key Components

### Core Module (`src/core/`)

- **app.c3**: App struct with HTTP method handlers (get, post, put, delete, patch)
- **context.c3**: Request context holding request, response, and route parameters
- **logger.c3**: Colored logging with info, warn, error, success, and debug levels
- **server.c3**: HTTP server accepting connections and dispatching handlers
- **socket.c3**: Socket handling for network communication

### HTTP Module (`src/http/`)

- **types.c3**: HttpMethod enum, StatusCode enum, Param and Header structs
- **response.c3**: Response helpers (text, options for CORS)
- **request.c3**: HTTP request parsing and handling
- **parser.c3**: HTTP protocol parsing utilities

### Router Module (`src/router/`)

- **router.c3**: Router with radix tree and linear search fallback
- **route.c3**: Route definition and handler function type alias
- **radix.c3**: Radix tree nodes and regex constraint matching

## Algorithm

The routing algorithm uses a **dual-strategy approach**:

1. **Radix Tree Search**: Primary method using a radix tree for O(k) path segment matching where k is path depth
   - Supports static segments (`/users`), parameters (`/:id`), optional parameters (`/:slug?`), wildcards (`/*path`), and regex constraints (`/:id(\\d+)`)
   - Segment types: STATIC, PARAM, PARAM_OPT, WILDCARD, GLOB

2. **Linear Search Fallback**: Sequential route matching as backup when radix tree fails

3. **Parameter Extraction**: Captures route parameters into context for handler access via `ctx.param("key")`

4. **Constraint Matching**: FSM-based regex pattern matching validates parameter values
   - Supports escape sequences: `\d` (digits), `\w` (word chars), `\s` (whitespace)
   - Supports quantifiers: `+` (one or more), `?` (optional), `*` (zero or more)
   - Supports dot (`.`) for any character matching
   - Extensible state machine architecture for adding new pattern features

## Usage Example

```c3
fn void main()
{
    App app = app::create();
    app::get(&app, "/", &get_root);
    app::get(&app, "/users/:id", &user_by_id);
    app::get(&app, "/files/*path", &get_files);
    app::get(&app, "/posts/:slug?", &get_posts);
    app::listen(&app, 8080);
}
```

## Building

```bash
./build.sh
```

This will compile the project using c3c and run the server on port 8080. 