module core::app;
import core::context;
import core::server;
import router::router;
import router::layer;
import router::radix;
import router::node;

struct App
{
    int    port;
    Router router;
}

fn void App.listen(&self, int port)
{
    self.port = port;
    server::server_run(self);
}

fn void App.use(&self, MiddlewareFn mw, String path = "/")
{
    Layer layer = {
        .type      = LayerType.MIDDLEWARE,
        .path      = path,
        .method    = "",
        .middleware = mw,
        .handler   = null
    };
    vec_push(&self.router.layers, layer);
}

fn void App.get(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.router.get_tree, path, handler);
}

fn void App.post(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.router.post_tree, path, handler);
}

fn void App.put(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.router.put_tree, path, handler);
}

fn void App.delete(&self, String path, HandlerFn handler)
{
    radix::radix_insert(&self.router.delete_tree, path, handler);
}

fn String path_join(String prefix, String path)
{
    bool prefix_has_slash = prefix.len > 0 && prefix[prefix.len - 1] == '/';
    bool path_has_slash   = path.len > 0 && path[0] == '/';

    String sep = "";
    if (prefix_has_slash && path_has_slash)
    {
        // Both have slashes - use prefix but skip path's leading slash
        path = path[1:path.len - 1];
    }
    else if (!prefix_has_slash && !path_has_slash && prefix.len > 0)
    {
        sep = "/";
    }

    usz total = prefix.len + sep.len + path.len;
    char[] data = mem::new_array(char, (sz)total);
    usz off = 0;
    if (prefix.len > 0)
    {
        mem::copy(data.ptr, prefix.ptr, (sz)prefix.len);
        off += prefix.len;
    }
    if (sep.len > 0)
    {
        mem::copy(&data[off], sep.ptr, (sz)sep.len);
        off += sep.len;
    }
    if (path.len > 0)
    {
        mem::copy(&data[off], path.ptr, (sz)path.len);
    }
    return (String)data;
}

fn void App.mount(&self, String prefix, Router* group)
{
    // Copy group middleware to app layers with path prefix
    for (int i = 0; i < (int)group.layers.len; i++)
    {
        Layer l = group.layers[i];
        String full = path_join(prefix, l.path);
        Layer nl = {
            .type      = LayerType.MIDDLEWARE,
            .path      = full,
            .method    = "",
            .middleware = l.middleware,
            .handler   = null
        };
        vec_push(&self.router.layers, nl);
    }

    // Copy group routes into app radix tree with prefix
    for (int i = 0; i < (int)group.routes.len; i++)
    {
        RouteReg r = group.routes[i];
        String full = path_join(prefix, r.path);

        if (r.method == "GET")
        {
            radix::radix_insert(&self.router.get_tree, full, r.handler);
        }
        else if (r.method == "POST")
        {
            radix::radix_insert(&self.router.post_tree, full, r.handler);
        }
        else if (r.method == "PUT")
        {
            radix::radix_insert(&self.router.put_tree, full, r.handler);
        }
        else if (r.method == "DELETE")
        {
            radix::radix_insert(&self.router.delete_tree, full, r.handler);
        }
    }
}

fn void vec_push(Layer[]* arr, Layer item)
{
    usz idx = arr.len;
    Layer[] new_arr = mem::new_array(Layer, (sz)(idx + 1));
    if (idx > 0) mem::copy(new_arr.ptr, arr.ptr, (sz)(idx * Layer::size));
    new_arr[idx] = item;
    *arr = new_arr;
}
