module http::request;

import http::types;

struct Request 
{
    types::HttpMethod method;
    String path;
    String version;
    types::Header[types::MAX_HEADERS] headers;
    sz headers_count;
}

fn String? Request.header(&self, String key)
{
    for (int i = 0; i < (int)self.headers_count; i++)
    {
        if (self.headers[i].key.compare_to_ignore_case(key) == 0)
        {
            return self.headers[i].value;
        }
    }
    String? result;
    return result;
}

fn types::HttpMethod parse_method_str(String s)
{
    if (s == "GET") return types::HttpMethod.GET;
    if (s == "POST") return types::HttpMethod.POST;
    if (s == "PUT") return types::HttpMethod.PUT;
    if (s == "DELETE") return types::HttpMethod.DELETE;
    if (s == "PATCH") return types::HttpMethod.PATCH;
    if (s == "HEAD") return types::HttpMethod.HEAD;
    if (s == "OPTIONS") return types::HttpMethod.OPTIONS;
    return types::HttpMethod.GET;
}
