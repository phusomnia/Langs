module http::response;
import http::headers;
import core::context;
import std::io;

struct Response
{
    int       status;
    HeaderMap headers;
    String    body;
    bool      sent;
}

struct MimeMap
{
    String ext;
    String mime;
}

const MimeMap[] MIME_TYPES = {
    { ".html", "text/html; charset=utf-8" },
    { ".htm",  "text/html; charset=utf-8" },
    { ".css",  "text/css; charset=utf-8" },
    { ".js",   "application/javascript; charset=utf-8" },
    { ".json", "application/json" },
    { ".png",  "image/png" },
    { ".jpg",  "image/jpeg" },
    { ".jpeg", "image/jpeg" },
    { ".gif",  "image/gif" },
    { ".svg",  "image/svg+xml" },
    { ".ico",  "image/x-icon" },
    { ".txt",  "text/plain; charset=utf-8" },
    { ".pdf",  "application/pdf" },
    { ".woff",   "font/woff" },
    { ".woff2",  "font/woff2" },
    { ".ttf",    "font/ttf" },
    { ".otf",    "font/otf" },
    { ".xml",    "application/xml" },
    { ".zip",    "application/zip" },
    { ".wasm",   "application/wasm" },
};

fn String mime_type(String ext)
{
    for (int i = 0; i < (int)MIME_TYPES.len; i++)
    {
        if (ext == MIME_TYPES[i].ext) return MIME_TYPES[i].mime;
    }
    return "application/octet-stream";
}

fn void ctx_text(Context* ctx, int status, String text)
{
    if (ctx.res.sent) return;

    ctx.res.status = status;
    ctx.res.body = text;
    headers::header_set(&ctx.res.headers, "Content-Type", "text/plain; charset=utf-8");

    ctx.res.sent = true;
}

fn String response_build_string(Response* response)
{
    String status_text = "Unknown";
    switch (response.status)
    {
        case 200: status_text = "OK"; break;
        case 201: status_text = "Created"; break;
        case 204: status_text = "No Content"; break;
        case 301: status_text = "Moved Permanently"; break;
        case 302: status_text = "Found"; break;
        case 304: status_text = "Not Modified"; break;
        case 400: status_text = "Bad Request"; break;
        case 401: status_text = "Unauthorized"; break;
        case 403: status_text = "Forbidden"; break;
        case 404: status_text = "Not Found"; break;
        case 405: status_text = "Method Not Allowed"; break;
        case 409: status_text = "Conflict"; break;
        case 413: status_text = "Payload Too Large"; break;
        case 429: status_text = "Too Many Requests"; break;
        case 500: status_text = "Internal Server Error"; break;
        case 502: status_text = "Bad Gateway"; break;
        case 503: status_text = "Service Unavailable"; break;
        default: break;
    }

    String ct = headers::header_get(&response.headers, "Content-Type");

    usz header_max = 256 + status_text.len + ct.len;
    usz total = header_max + response.body.len;
    char[] buf = mem::new_array(char, (sz)total);
    sz used = 0;

    String line = (String)io::bprintf(buf[used..], "HTTP/1.1 %d %s\r\n", response.status, status_text)!!;
    used += (sz)line.len;

    if (ct.len > 0)
    {
        line = (String)io::bprintf(buf[used..], "Content-Type: %s\r\n", ct)!!;
        used += (sz)line.len;
    }

    line = (String)io::bprintf(buf[used..], "Content-Length: %d\r\n", (int)response.body.len)!!;
    used += (sz)line.len;

    line = (String)io::bprintf(buf[used..], "Connection: close\r\n")!!;
    used += (sz)line.len;

    line = (String)io::bprintf(buf[used..], "\r\n")!!;
    used += (sz)line.len;

    if (response.body.len > 0)
    {
        mem::copy(&buf[used], response.body.ptr, (sz)response.body.len);
        used += (sz)response.body.len;
    }

    return (String)buf[:used];
}

fn String http_serialize_response(Response* response)
{
    return response_build_string(response);
}
