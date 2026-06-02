module core::server;
import core::app;
import core::context;
import http::request;
import http::response;
import http::parser;
import http::headers;
import middleware::compose;
import router::radix;
import router::node;
import router::layer;
import runtime::socket;
import std::io;

fn void server_run(App* app)
{
    io::printfn("Server listening on http://localhost:%d", app.port);

    for (;;)
    {
        Socket conn = socket::socket_accept(app.port);
        io::printfn("[%d] New connection accepted", app.port);

        server_handle_request(app, &conn);
    }
}

fn void server_handle_request(App* app, Socket* conn)
{
    String   raw = socket::socket_read_all(conn);

    Request  req = parser::http_parse_request(raw);
    io::printfn("[%d] %s %s", app.port, req.method, req.path);

    Response res = {};

    Context  ctx = {
        .req      = req,
        .res      = res,
        .app      = app,
        .params   = {},
        .finished = false
    };

    // Run middleware chain
    compose::dispatch(&ctx, app.router.layers, 0);

    // After middleware, do radix tree lookup by HTTP method
    Node* matched = null;

    if (ctx.req.method == "GET")
    {
        matched = radix::radix_search(app.router.get_tree, ctx.req.path, &ctx.params);
    }
    else if (ctx.req.method == "POST")
    {
        matched = radix::radix_search(app.router.post_tree, ctx.req.path, &ctx.params);
    }
    else if (ctx.req.method == "PUT")
    {
        matched = radix::radix_search(app.router.put_tree, ctx.req.path, &ctx.params);
    }
    else if (ctx.req.method == "DELETE")
    {
        matched = radix::radix_search(app.router.delete_tree, ctx.req.path, &ctx.params);
    }

    if (matched != null && matched.handler != null && !ctx.res.sent)
    {
        matched.handler(&ctx);
    }
    else if (!ctx.res.sent)
    {
        response::ctx_text(&ctx, 404, "Not found");
    }

    String out = response::http_serialize_response(&ctx.res);
    io::printfn("[%d] -> %d (%d bytes)", app.port, ctx.res.status, out.len);
    socket::socket_write(conn, out);
    socket::socket_close(conn);
}
