module router::layer;
import core::context;

alias NextFn = fn void(Context*);
alias MiddlewareFn = fn void(Context*, NextFn);
alias HandlerFn = fn void(Context*);

enum LayerType
{
    MIDDLEWARE,
    ROUTE
}

struct Layer
{
    LayerType    type;
    String       path;
    String       method;
    MiddlewareFn middleware;
    HandlerFn    handler;
}
