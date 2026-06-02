module router::router;
import router::layer;
import router::node;
import router::radix;
import core::context;

struct RouteReg
{
    String      method;
    String      path;
    HandlerFn   handler;
}

struct Router
{
    Node*       get_tree;
    Node*       post_tree;
    Node*       put_tree;
    Node*       delete_tree;
    Layer[]     layers;
    RouteReg[]  routes;
}

fn void Router.use(&self, MiddlewareFn mw, String path = "/")
{
    Layer layer = {
        .type      = LayerType.MIDDLEWARE,
        .path      = path,
        .method    = "",
        .middleware = mw,
        .handler   = null
    };
    vec_push(&self.layers, layer);
}

fn void Router.get(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.get_tree, path, handler);
    RouteReg reg = { .method = "GET", .path = path, .handler = handler };
    routevec_push(&self.routes, reg);
}

fn void Router.post(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.post_tree, path, handler);
    RouteReg reg = { .method = "POST", .path = path, .handler = handler };
    routevec_push(&self.routes, reg);
}

fn void Router.put(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.put_tree, path, handler);
    RouteReg reg = { .method = "PUT", .path = path, .handler = handler };
    routevec_push(&self.routes, reg);
}

fn void Router.delete(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.delete_tree, path, handler);
    RouteReg reg = { .method = "DELETE", .path = path, .handler = handler };
    routevec_push(&self.routes, reg);
}

fn void vec_push(Layer[]* arr, Layer item)
{
    usz idx = arr.len;
    Layer[] new_arr = mem::new_array(Layer, (sz)(idx + 1));
    if (idx > 0) mem::copy(new_arr.ptr, arr.ptr, (sz)(idx * Layer::size));
    new_arr[idx] = item;
    *arr = new_arr;
}

fn void routevec_push(RouteReg[]* arr, RouteReg item)
{
    usz idx = arr.len;
    RouteReg[] new_arr = mem::new_array(RouteReg, (sz)(idx + 1));
    if (idx > 0) mem::copy(new_arr.ptr, arr.ptr, (sz)(idx * RouteReg::size));
    new_arr[idx] = item;
    *arr = new_arr;
}
