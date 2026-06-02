module http::types;

const MAX_PARAMS = 16;
const MAX_HEADERS = 32;

struct Param
{
    String key;
    String value;
}

struct Header
{
    String key;
    String value;
}

enum HttpMethod
{
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
}

enum StatusCode : int (int code)
{
    OK { 200 },
    CREATED { 201 },
    NO_CONTENT { 204 },
    MOVED_PERMANENTLY { 301 },
    BAD_REQUEST { 400 },
    UNAUTHORIZED { 401 },
    FORBIDDEN { 403 },
    NOT_FOUND { 404 },
    METHOD_NOT_ALLOWED { 405 },
    CONFLICT { 409 },
    INTERNAL_SERVER_ERROR { 500 },
    BAD_GATEWAY { 502 },
    SERVICE_UNAVAILABLE { 503 },
}

fn String StatusCode.reason(&self)
{
    switch (*self)
    {
        case OK: return "OK";
        case CREATED: return "Created";
        case NO_CONTENT: return "No Content";
        case MOVED_PERMANENTLY: return "Moved Permanently";
        case BAD_REQUEST: return "Bad Request";
        case UNAUTHORIZED: return "Unauthorized";
        case FORBIDDEN: return "Forbidden";
        case NOT_FOUND: return "Not Found";
        case METHOD_NOT_ALLOWED: return "Method Not Allowed";
        case CONFLICT: return "Conflict";
        case INTERNAL_SERVER_ERROR: return "Internal Server Error";
        case BAD_GATEWAY: return "Bad Gateway";
        case SERVICE_UNAVAILABLE: return "Service Unavailable";
        default: return "Unknown";
    }
}
