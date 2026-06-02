# Express C3

## Architecture 
```
TCP Server
    ↓
HTTP Parser
    ↓
App
    ↓
Middleware Stack
    ↓
Router
    ↓
Route Layer
    ↓
Handler
    ↓
Response Writer
```

## Project Structure
```
/src
    /core
        app.c3
        server.c3
        context.c3

    /http
        request.c3
        response.c3
        parser.c3
        headers.c3

    /router
        router.c3
        route.c3
        layer.c3
        matcher.c3

    /middleware
        middleware.c3
        compose.c3

    /runtime
        socket.c3
        threadpool.c3
        arena.c3

    /utils
        string.c3
        hashmap.c3
        vec.c3
```

## Internal Architecture
```
Application
  └── Router
        └── Layers
              └── Handlers
```

## Core Object Design
## App
## Router
## Route
## Layer

## Request LifeCycle
```
socket accept
    ↓
parse HTTP
    ↓
create Context
    ↓
execute middleware stack
    ↓
route matching
    ↓
execute handler
    ↓
serialize response
    ↓
write socket
```

## Context Object
Thay vì req/res riêng lẻ như Express:
Better design for C3

```
struct Context
{
    Request req;
    Response res;

    App* app;

    Arena* arena;

    bool finished;
}
```
Inspired by: Gin, Echo, Fiber

## Middleware System
## Middleware signature
```
fn void Middleware(Context* ctx, NextFn next)
```
example: 
```
fn void logger(Context* ctx, NextFn next)
{
    io::printn(ctx.req.path);

    next(ctx);
}
```

## Middleware Composition Engine
## Internal flow
```
middlewares[0]
    ↓ next()
middlewares[1]
    ↓ next()
route handler
```

## Dispatcher design
```
fn void dispatch(Context* ctx, int index)
{
    if (index >= stack.len)
        return;

    MiddlewareFn fn = stack[index];

    fn(ctx, fn () {
        dispatch(ctx, index + 1);
    });
}
```

## Router API
## App-level
```
app_get(app, "/", home);
app_post(app, "/users", create_user);
```
## Router level
```
Router api = router_create();

router_get(&api, "/users", users);

app_use_router(app, "/api", &api);
```

## Route Matching
## V1 
Linear scan:
```
for route in routes:
    if path == route.path:
        return route
```
## V2
Radix tree.
Support:
```
/users/:id
/files/*
```

## HTTP Parser
## Parse:
### request line
```
GET /users HTTP/1.1
```
### headers
```
Host: localhost
```
### body
Need:
* content-length
* chunked
* multipart later

## Request Object
```
struct Request
{
    String method;
    String path;
    String query;

    HeaderMap headers;

    String body;

    ParamMap params;
}
```
## Response Object
```
struct Response
{
    int status;

    HeaderMap headers;

    String body;

    bool sent;
}
```

## Response Helpers
## Text
```
ctx_text(ctx, 200, "hello");
```
## JSON
```
ctx_json(ctx, 200, data);
```
## HTML
```
ctx_html(ctx, html);
```

## Error Handling

Express có:
```
(err, req, res, next)
```

## Better C3 design
```
fn void ErrorHandler(Context* ctx, Error err)
```

Global catcher:
```
middleware panic
    ↓
recover
    ↓
500 response
```

## Memory Management
## Arena per request

VERY IMPORTANT.
```
request start
    create arena
request end
    free arena
```

Benefits:
* zero GC
* fast cleanup
* predictable memory

## Runtime Architecture
Recommended
Thread pool
```
accept thread
    ↓
worker queue
    ↓
worker threads
```
Avoid initially:
async runtime
coroutine scheduler
Too complex.

## Static File Middleware

Like:
```
app.use(static("public"))
```
Need:
* mime types
* caching
* file streaming

## Body Parser Middleware
```
app_use(json_parser());

Transforms:

{"name":"john"}
```

into:

```
ctx.req.json
```
## Internal Stack Model
This is CRITICAL

Everything becomes Layer.
```
[
    logger middleware,
    cors middleware,
    auth middleware,
    router middleware,
    route handler
]
```
This is literally Express architecture.

## Performance Strategy
Hot paths

Optimize:
* path matching
* header parsing
* allocations
* response write

Avoid:
* string copies
* heap allocation
* regex routing initially

23. Suggested MVP Roadmap
Phase 1
TCP server
HTTP parser
plain response
Phase 2
middleware stack
route matching
Phase 3
nested routers
params
Phase 4
JSON
static files
logger
Phase 5
keep-alive
threadpool
benchmarks
24. Example Final API
User-facing syntax
fn void logger(Context* ctx, NextFn next)
{
    io::printn(ctx.req.path);

    next(ctx);
}

fn void home(Context* ctx)
{
    ctx_text(ctx, 200, "Hello");
}

fn void main()
{
    App app = app_create();

    app_use(&app, logger);

    app_get(&app, "/", home);

    app_listen(&app, 8080);
}
25. Long-Term Vision
V2 Features
websocket
HTTP/2
async middleware
template engine
ORM hooks
plugin system
26. Important Design Advice

Đừng bắt đầu từ syntax.

Bắt đầu từ:

middleware engine
→ routing
→ dispatch
→ memory model
