module core::server;

import core::log;
import core::context;
import core::socket;
import http::request;
import http::types;
import std::net;

alias HandlerFn = fn void(context::Context* ctx);

fn void read_headers(context::Context* ctx)
{
    socket::Socket* client = ctx.client;
    while (ctx.req.headers_count < types::MAX_HEADERS)
    {
        if (try hline = client.read_line())
        {
            if (hline.len == 0) { log::debug("  headers: end (empty line)"); break; }

            String[] hparts = hline.tsplit(":", 2);
            if (hparts.len == 2)
            {
                ctx.req.headers[ctx.req.headers_count].key = hparts[0].trim();
                ctx.req.headers[ctx.req.headers_count].value = hparts[1].trim();
                ctx.req.headers_count++;
            }
        }
        else { log::debug("  headers: read error/EOF"); break; }
    }
    log::debug("  headers: parsed %d headers", (int)ctx.req.headers_count);
}

fn void run(int port, HandlerFn handler, void* app_data = null){
    log::info("Server started");

    socket::Server server = socket::listen("127.0.0.1", port, SocketOption.REUSEADDR);
    log::info("Server running on port http://localhost:%d", port);

    while (true)
    {
        socket::Socket client = server.accept() !!;
        log::debug(" connection accepted");
        defer {
            client.shutdown(net::SocketShutdownHow.SEND);
            client.close();
            log::debug(" connection closed");
        }

        context::Context ctx;
        ctx.client = &client;
        ctx.res.client = &client;
        ctx.res.suppress_body = false;
        ctx.app_data = app_data;
        ctx.params_count = 0;
        ctx.req.headers_count = 0;

        String? raw = client.read_line();
        if (try raw)
        {
            log::debug(" request line: '%s'", raw);
            String[] parts = raw.tsplit(" ");
            if (parts.len >= 3)
            {
                ctx.req.method = request::parse_method_str(parts[0]);
                ctx.req.path = parts[1];
                ctx.req.version = parts[2];
                log::debug(" => %s '%s' %s",
                    request::parse_method_str(parts[0]) == types::HttpMethod.GET ? "GET" :
                    request::parse_method_str(parts[0]) == types::HttpMethod.POST ? "POST" :
                    request::parse_method_str(parts[0]) == types::HttpMethod.PUT ? "PUT" :
                    request::parse_method_str(parts[0]) == types::HttpMethod.DELETE ? "DELETE" :
                    request::parse_method_str(parts[0]) == types::HttpMethod.PATCH ? "PATCH" :
                    request::parse_method_str(parts[0]) == types::HttpMethod.HEAD ? "HEAD" :
                    request::parse_method_str(parts[0]) == types::HttpMethod.OPTIONS ? "OPTIONS" : "UNKNOWN",
                    parts[1],
                    parts[2]);

                read_headers(&ctx);

                handler(&ctx);
            }
            else
            {
                log::debug(" => invalid request line (only %d parts)", (int)parts.len);
            }
        }
        else
        {
            log::debug(" => no request line received");
        }
    }
}
