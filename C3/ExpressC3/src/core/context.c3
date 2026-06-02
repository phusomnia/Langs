module core::context;
import http::request;
import http::response;
import http::headers;
import core::app;

struct Context
{
    Request   req;
    Response  res;
    App*      app;
    HeaderMap params;
    bool      finished;
}
