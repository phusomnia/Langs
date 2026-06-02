module http::request;
import http::headers;

struct Request 
{
    String    method;
    String    path;
    String    query;
    String    version;

    HeaderMap headers;
    String    body;
}