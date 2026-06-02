module core::app;

import core::server;
import core::context;
import core::log;
import router::router;
import router::route;
import http::types;
import http::response;

struct App
{
    router::Router router;
}

fn App create()
{
    App app;
    app.router = router::init();
    return app;
}

fn void get(App* app, String path, route::HandlerFn handler)
{
    router::add(&app.router, types::HttpMethod.GET, path, handler);
}

fn void post(App* app, String path, route::HandlerFn handler)
{
    router::add(&app.router, types::HttpMethod.POST, path, handler);
}

fn void put(App* app, String path, route::HandlerFn handler)
{
    router::add(&app.router, types::HttpMethod.PUT, path, handler);
}

fn void delete(App* app, String path, route::HandlerFn handler)
{
    router::add(&app.router, types::HttpMethod.DELETE, path, handler);
}

fn void patch(App* app, String path, route::HandlerFn handler)
{
    router::add(&app.router, types::HttpMethod.PATCH, path, handler);
}

fn void handle(context::Context* ctx)
{
    App* app = ctx.app_data;
    route::HandlerFn h;

    log::debug(" app::handle: dispatching");

    if (ctx.req.method == types::HttpMethod.HEAD)
    {
        if (router::find(&app.router, types::HttpMethod.HEAD, ctx.req.path, &h, &ctx.params, &ctx.params_count))
        {
            log::debug(" app::handle: HEAD handler found");
            h(ctx);
            return;
        }
        if (router::find(&app.router, types::HttpMethod.GET, ctx.req.path, &h, &ctx.params, &ctx.params_count))
        {
            log::debug(" app::handle: HEAD -> GET handler (body suppressed)");
            ctx.res.suppress_body = true;
            h(ctx);
            return;
        }
        log::debug(" app::handle: HEAD not found -> 404");
        response::text(ctx, types::StatusCode.NOT_FOUND, "Not Found");
        return;
    }

    if (ctx.req.method == types::HttpMethod.OPTIONS)
    {
        log::debug(" app::handle: OPTIONS");
        response::options(ctx, &app.router, ctx.req.path);
        return;
    }

    if (router::find(&app.router, ctx.req.method, ctx.req.path, &h, &ctx.params, &ctx.params_count))
    {
        log::debug(" app::handle: handler found, dispatching");
        h(ctx);
        log::debug(" app::handle: handler returned");
    }
    else
    {
        log::debug(" app::handle: no handler -> 404");
        response::text(ctx, types::StatusCode.NOT_FOUND, "Not Found");
    }
}

fn void listen(App* app, int port)
{
    server::run(port, &handle, app);
}
