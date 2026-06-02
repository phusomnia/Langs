module http::response;

import core::socket;
import core::context;
import http::types;
import router::router;
import router::route;
import std::io;

struct Response
{
    socket::Socket* client;
    bool suppress_body;
}

struct BufData { char[1024] buf; sz written; }

fn void? buf_write(void* data, char c)
{
    BufData* b = data;
    if (b.written >= 1024) return io::BUFFER_EXCEEDED~;
    b.buf[b.written++] = c;
}

fn void text(context::Context* ctx, types::StatusCode code, String body)
{
    socket::Socket* client = ctx.client;
    BufData bd;
    io::Formatter f;

    f.init(&buf_write, &bd);
    f.printf("HTTP/1.1 %d %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\n\r\n",
             code.code, code.reason(), (int)body.len) !!;
    client.write((String)bd.buf[:bd.written]);
    if (!ctx.res.suppress_body)
    {
        client.write(body);
    }
}

fn String method_name(types::HttpMethod m)
{
    if (m == types::HttpMethod.GET) return "GET";
    if (m == types::HttpMethod.POST) return "POST";
    if (m == types::HttpMethod.PUT) return "PUT";
    if (m == types::HttpMethod.DELETE) return "DELETE";
    if (m == types::HttpMethod.PATCH) return "PATCH";
    if (m == types::HttpMethod.HEAD) return "HEAD";
    if (m == types::HttpMethod.OPTIONS) return "OPTIONS";
    return "UNKNOWN";
}

fn void options(context::Context* ctx, router::Router* router, String path)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("HTTP/1.1 200 OK\r\nAllow: ") !!;

    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] tmp_params;
    sz tmp_count;
    bool first = true;

    types::HttpMethod[6] methods = {
        types::HttpMethod.GET,
        types::HttpMethod.POST,
        types::HttpMethod.PUT,
        types::HttpMethod.DELETE,
        types::HttpMethod.PATCH,
        types::HttpMethod.HEAD,
    };

    for (int i = 0; i < (int)methods.len; i++)
    {
        if (router::find(router, methods[i], path, &h, &tmp_params, &tmp_count))
        {
            if (!first) { f.printf(", ") !!; }
            first = false;
            f.printf(method_name(methods[i])) !!;
        }
    }

    f.printf("\r\nContent-Length: 0\r\n\r\n") !!;
    ctx.client.write((String)bd.buf[:bd.written]);
}
