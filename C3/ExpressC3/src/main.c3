module express_c3;
import core::context;
import core::app;
import http::response;
import http::headers;
import middleware::static_file;
import router::layer;
import router::router;
import std::io;

fn void home(Context* ctx)
{
    response::ctx_text(ctx, 200, "Hello from Express C3");
}

fn void users(Context* ctx)
{
    response::ctx_text(ctx, 200, "Users");
}

fn void user_detail(Context* ctx)
{
    String id = headers::header_get(&ctx.params, "id");

    String prefix = "User: ";
    usz total = prefix.len + id.len;
    char[] data = mem::new_array(char, (sz)total);
    mem::copy(data.ptr, prefix.ptr, (sz)prefix.len);
    mem::copy(&data[prefix.len], id.ptr, (sz)id.len);

    response::ctx_text(ctx, 200, (String)data);
}

fn void user_profile(Context* ctx)
{
    String id = headers::header_get(&ctx.params, "id");

    String prefix = "Profile of user: ";
    usz total = prefix.len + id.len;
    char[] data = mem::new_array(char, (sz)total);
    mem::copy(data.ptr, prefix.ptr, (sz)prefix.len);
    mem::copy(&data[prefix.len], id.ptr, (sz)id.len);

    response::ctx_text(ctx, 200, (String)data);
}

fn void api_users(Context* ctx)
{
    response::ctx_text(ctx, 200, "API Users");
}

fn void api_user_by_id(Context* ctx)
{
    String id = headers::header_get(&ctx.params, "id");

    String prefix = "API User: ";
    usz total = prefix.len + id.len;
    char[] data = mem::new_array(char, (sz)total);
    mem::copy(data.ptr, prefix.ptr, (sz)prefix.len);
    mem::copy(&data[prefix.len], id.ptr, (sz)id.len);

    response::ctx_text(ctx, 200, (String)data);
}

fn void logger(Context* ctx, NextFn next)
{
    io::printfn("[Logger]: %s %s", ctx.req.method, ctx.req.path);
    next(ctx);
}

fn void api_logger(Context* ctx, NextFn next)
{
    io::printfn("[API Logger]: %s %s", ctx.req.method, ctx.req.path);
    next(ctx);
}

fn void main()
{
    // Build API route group
    Router api = {};
    api.use(&api_logger);
    api.get("/users", &api_users);
    api.get("/users/:id", &api_user_by_id);

    // Build main app
    App app = {};
    app.port = 8080;

    app.use(&logger);

    // Serve static files with auto extension resolution
    app.use(static_file::serve("src/resources/static", {
        .extensions = { "html", "htm" }
    }));

    app.get("/", &home);
    app.get("/users", &users);
    app.get("/users/:id", &user_detail);
    app.get("/users/:id/profile", &user_profile);

    // Mount the API group under /api prefix
    app.mount("/api", &api);

    app.listen(8080);
}
