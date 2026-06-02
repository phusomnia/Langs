module middleware::static_file;
import core::context;
import http::headers;
import http::response;
import router::layer;
import std::io;
import std::io::file;

struct StaticFileOptions
{
    String[] extensions;
}

String _root;
String[] _extensions;
bool _initialized = false;

fn void handler(Context* ctx, NextFn next)
{
    if (!_initialized || ctx.res.sent)
    {
        next(ctx);
        return;
    }

    String url_path = ctx.req.path;

    if (contains_dot_dot(url_path))
    {
        next(ctx);
        return;
    }

    String filepath = join_paths(_root, url_path);

    if (try_serve(ctx, filepath)) return;

    if (get_extension(filepath).len == 0)
    {
        for (int i = 0; i < (int)_extensions.len; i++)
        {
            String try_path = append_ext(filepath, _extensions[i]);
            if (try_serve(ctx, try_path)) return;
        }
    }

    next(ctx);
}

fn MiddlewareFn serve(String root, StaticFileOptions opts = {})
{
    _root = root;
    _extensions = opts.extensions;
    _initialized = true;
    return &handler;
}

fn bool try_serve(Context* ctx, String filepath)
{
    if (!file::is_file(filepath)) return false;

    io::File f = file::open(filepath, "rb")!!;
    defer (void)f.close();

    long len = f.size()!!;
    char[] data = mem::new_array(char, (sz)len);

    sz total = 0;
    while (total < (sz)len)
    {
        total += f.read(data[total..])!!;
    }

    ctx.res.status = 200;
    ctx.res.body = (String)data;

    String ext = get_extension(filepath);
    String ct = response::mime_type(ext);
    headers::header_set(&ctx.res.headers, "Content-Type", ct);

    ctx.res.sent = true;
    return true;
}

fn String join_paths(String dir, String url_path)
{
    usz start = 0;
    while (start < url_path.len && url_path[start] == '/') start++;

    String rel = url_path[start..];
    if (rel.len == 0) return dir;

    bool dir_has_sep = dir.len > 0 && (dir[dir.len - 1] == '/' || dir[dir.len - 1] == '\\');

    usz total = dir.len + (dir_has_sep ? 0 : 1) + rel.len;
    char[] data = mem::new_array(char, (sz)total);
    usz off = 0;

    mem::copy(data.ptr, dir.ptr, (sz)dir.len);
    off += dir.len;
    if (!dir_has_sep)
    {
        data[off] = '/';
        off++;
    }
    mem::copy(&data[off], rel.ptr, (sz)rel.len);

    return (String)data;
}

fn String get_extension(String path)
{
    usz dot = 0;
    usz last_sep = 0;

    for (usz i = 0; i < path.len; i++)
    {
        if (path[i] == '.') dot = i;
        if (path[i] == '/' || path[i] == '\\') last_sep = i;
    }

    if (dot > 0 && dot > last_sep) return path[dot..];

    return "";
}

fn String append_ext(String path, String ext)
{
    usz total = path.len + 1 + ext.len;
    char[] data = mem::new_array(char, (sz)total);
    mem::copy(data.ptr, path.ptr, (sz)path.len);
    data[path.len] = '.';
    mem::copy(&data[path.len + 1], ext.ptr, (sz)ext.len);
    return (String)data;
}

fn bool contains_dot_dot(String path)
{
    for (usz i = 0; i < path.len; i++)
    {
        if (i + 1 < path.len && path[i] == '.' && path[i + 1] == '.')
        {
            bool start_ok = i == 0 || path[i - 1] == '/' || path[i - 1] == '\\';
            bool end_ok = i + 2 >= path.len || path[i + 2] == '/' || path[i + 2] == '\\';
            if (start_ok && end_ok) return true;
        }
    }
    return false;
}
