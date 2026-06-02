module router::route;

import core::context;
import http::types;

alias HandlerFn = fn void(context::Context* ctx);

struct Route
{
    types::HttpMethod method;
    String path;
    HandlerFn handler;
}
