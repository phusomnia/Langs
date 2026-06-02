module http::parser;
import http::request;
import http::headers;

fn Request http_parse_request(String raw)
{
    Request req = {};

    if (raw.len == 0) return req;

    usz pos = 0;

    while (pos < raw.len && raw[pos] == ' ') pos++;
    usz start = pos;
    while (pos < raw.len && raw[pos] != ' ') pos++;
    if (pos > start) req.method = raw[start:pos - start];

    while (pos < raw.len && raw[pos] == ' ') pos++;
    start = pos;
    while (pos < raw.len && raw[pos] != ' ' && raw[pos] != '?') pos++;
    if (pos > start) req.path = raw[start:pos - start];

    if (pos < raw.len && raw[pos] == '?')
    {
        start = pos + 1;
        while (pos < raw.len && raw[pos] != ' ') pos++;
        if (pos > start) req.query = raw[start:pos - start];
    }

    while (pos < raw.len && raw[pos] == ' ') pos++;
    start = pos;
    while (pos < raw.len && raw[pos] != '\r' && raw[pos] != '\n') pos++;
    if (pos > start) req.version = raw[start:pos - start];

    return req;
}
