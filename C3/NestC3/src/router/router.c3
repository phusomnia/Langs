module router::router;

import router::radix;
import router::route;
import http::types;
import core::log;

const NODE_POOL_SIZE = 64;
const LINEAR_ROUTES = 128;

struct Router
{
    radix::Node[NODE_POOL_SIZE] node_pool;
    sz node_count;
    route::Route[LINEAR_ROUTES] linear;
    sz linear_count;
}

fn Router init()
{
    Router r;
    r.node_pool[0].part = "/";
    r.node_pool[0].type = radix::SegmentType.STATIC;
    r.node_pool[0].children_count = 0;
    r.node_pool[0].has_handler = false;
    r.node_count = 1;
    r.linear_count = 0;
    return r;
}

fn radix::SegmentType classify_segment(String raw, String* out_part, String* out_key, String* out_constraint)
{
    if (raw.len == 0) { return radix::SegmentType.STATIC; }

    if (raw[0] == ':')
    {
        String rest = raw[1..];
        *out_key = rest;
        *out_part = rest;
        *out_constraint = "";

        if (try paren = rest.index_of("("))
        {
            if (try close = rest.index_of(")"))
            {
                if ((int)close > (int)paren + 1)
                {
                    int p = (int)paren;
                    int c = (int)close;
                    *out_constraint = rest[p + 1 .. c - 1];
                    *out_part = rest[..p - 1];
                    *out_key = *out_part;
                }
            }
        }

        String part = *out_part;
        if (part.len > 0)
        {
            if (part[part.len - 1] == '?')
            {
                *out_key = part[..part.len - 2];
                *out_part = *out_key;
                if ((*out_constraint).len > 0) { 
                    log::debug("  classify '%s' => GLOB (key=%s, constraint=%s)", raw, *out_key, *out_constraint); return radix::SegmentType.GLOB; 
                }
                log::debug("  classify '%s' => PARAM_OPT (key=%s)", raw, *out_key);
                return radix::SegmentType.PARAM_OPT;
            }
        }

        if ((*out_constraint).len > 0) { 
            log::debug("  classify '%s' => GLOB (key=%s, constraint=%s)", raw, *out_key, *out_constraint); 
            return radix::SegmentType.GLOB; 
        }
        log::debug("  classify '%s' => PARAM (key=%s)", raw, *out_key);
        return radix::SegmentType.PARAM;
    }

    if (raw[0] == '*')
    {
        *out_key = raw[1..];
        *out_part = *out_key;
        log::debug("  classify '%s' => WILDCARD (key=%s)", raw, *out_key);
        return radix::SegmentType.WILDCARD;
    }

    *out_part = raw;
    log::debug("  classify '%s' => STATIC", raw);
    return radix::SegmentType.STATIC;
}

fn String method_to_str(types::HttpMethod m)
{
    if (m == types::HttpMethod.GET) return "GET";
    if (m == types::HttpMethod.POST) return "POST";
    if (m == types::HttpMethod.PUT) return "PUT";
    if (m == types::HttpMethod.DELETE) return "DELETE";
    if (m == types::HttpMethod.PATCH) return "PATCH";
    if (m == types::HttpMethod.HEAD) return "HEAD";
    if (m == types::HttpMethod.OPTIONS) return "OPTIONS";
    return "UNKNOWN";
}

fn void add(Router* r, types::HttpMethod method, String path, route::HandlerFn handler)
{
    log::debug("  add: radix insert '%s %s'", method_to_str(method), path);

    sz current = 0;

    String[] parts = path.tsplit("/");

    for (int i = 0; i < (int)parts.len; i++)
    {
        String raw = parts[i];
        if (raw.len == 0) { continue; }

        String spart;
        String skey;
        String sconstraint;
        radix::SegmentType stype = classify_segment(raw, &spart, &skey, &sconstraint);

        sz next_idx;
        bool found = false;

        radix::Node* cur = &r.node_pool[current];

        if (stype == radix::SegmentType.STATIC)
        {
            for (int j = 0; j < (int)cur.children_count; j++)
            {
                sz child_idx = cur.children[j];
                radix::Node* child = &r.node_pool[child_idx];
                if (child.type == radix::SegmentType.STATIC && child.part == spart)
                {
                    next_idx = child_idx;
                    found = true;
                    break;
                }
            }
        }
        else
        {
            for (int j = 0; j < (int)cur.children_count; j++)
            {
                sz child_idx = cur.children[j];
                if (r.node_pool[child_idx].type == stype)
                {
                    next_idx = child_idx;
                    found = true;
                    break;
                }
            }
        }

        if (!found)
        {
            next_idx = r.node_count;
            r.node_count++;
            r.node_pool[next_idx].part = spart;
            r.node_pool[next_idx].type = stype;
            r.node_pool[next_idx].key = skey;
            r.node_pool[next_idx].constraint = sconstraint;
            r.node_pool[next_idx].children_count = 0;
            r.node_pool[next_idx].has_handler = false;
            cur.children[cur.children_count] = next_idx;
            cur.children_count++;
        }

        current = next_idx;
    }

    r.node_pool[current].handler = handler;
    r.node_pool[current].method = method;
    r.node_pool[current].has_handler = true;

    sz idx = r.linear_count;
    r.linear[idx].method = method;
    r.linear[idx].path = path;
    r.linear[idx].handler = handler;
    r.linear_count++;

    log::debug("  add: done (node_idx=%d, linear_idx=%d)", (int)current, (int)idx);
}

fn bool match_node(Router* r, sz node_idx, int part_idx, String[] parts,
                   types::HttpMethod method, route::HandlerFn* out,
                   types::Param* params, sz* count)
{
    bool is_end = part_idx >= (int)parts.len;
    log::debug("    match_node(idx=%d, part_idx=%d/%d, is_end=%d)", (int)node_idx, part_idx, (int)parts.len, is_end);

    if (is_end)
    {
        radix::Node* n = &r.node_pool[node_idx];
        if (n.has_handler && n.method == method)
        {
            log::debug("      -> handler FOUND at node %d", (int)node_idx);
            *out = n.handler;
            return true;
        }
        for (int j = 0; j < (int)n.children_count; j++)
        {
            sz cidx = n.children[j];
            if (r.node_pool[cidx].type == radix::SegmentType.PARAM_OPT)
            {
                sz saved = *count;
                if (match_node(r, cidx, part_idx, parts, method, out, params, count)) { return true; }
                *count = saved;
            }
        }
        log::debug("      -> no match at end");
        return false;
    }

    String seg = parts[part_idx];
    if (seg.len == 0) { return match_node(r, node_idx, part_idx + 1, parts, method, out, params, count); }

    radix::Node* cur = &r.node_pool[node_idx];
    sz saved = *count;

    for (int j = 0; j < (int)cur.children_count; j++)
    {
        sz cidx = cur.children[j];
        radix::Node* c = &r.node_pool[cidx];

        if (c.type == radix::SegmentType.STATIC && c.part == seg)
        {
            log::debug("      try STATIC '%s'", c.part);
            if (match_node(r, cidx, part_idx + 1, parts, method, out, params, count)) { return true; }
        }
    }

    *count = saved;
    for (int j = 0; j < (int)cur.children_count; j++)
    {
        sz cidx = cur.children[j];
        radix::Node* c = &r.node_pool[cidx];

        if (c.type == radix::SegmentType.PARAM)
        {
            log::debug("      try PARAM key='%s' value='%s'", c.key, seg);
            params[*count] = { .key = c.key, .value = seg };
            (*count)++;
            if (match_node(r, cidx, part_idx + 1, parts, method, out, params, count)) { return true; }
            *count = saved;
        }
    }

    for (int j = 0; j < (int)cur.children_count; j++)
    {
        sz cidx = cur.children[j];
        radix::Node* c = &r.node_pool[cidx];

        if (c.type == radix::SegmentType.GLOB && radix::match_constraint(seg, c.constraint))
        {
            log::debug("      try GLOB key='%s' value='%s'", c.key, seg);
            params[*count] = { .key = c.key, .value = seg };
            (*count)++;
            if (match_node(r, cidx, part_idx + 1, parts, method, out, params, count)) { return true; }
            *count = saved;
        }
    }

    for (int j = 0; j < (int)cur.children_count; j++)
    {
        sz cidx = cur.children[j];
        radix::Node* c = &r.node_pool[cidx];

        if (c.type == radix::SegmentType.PARAM_OPT)
        {
            log::debug("      try PARAM_OPT key='%s' (optional skip)", c.key);
            if (match_node(r, cidx, part_idx, parts, method, out, params, count)) { return true; }

            *count = saved;
            log::debug("      try PARAM_OPT key='%s' value='%s'", c.key, seg);
            params[*count] = { .key = c.key, .value = seg };
            (*count)++;
            if (match_node(r, cidx, part_idx + 1, parts, method, out, params, count)) { return true; }
            *count = saved;
        }
    }

    for (int j = 0; j < (int)cur.children_count; j++)
    {
        sz cidx = cur.children[j];
        radix::Node* c = &r.node_pool[cidx];

        if (c.type == radix::SegmentType.WILDCARD && c.has_handler && c.method == method)
        {
            char[1024] wc_buf;
            sz wpos = 0;
            for (int k = part_idx; k < (int)parts.len; k++)
            {
                if (k > part_idx) { wc_buf[wpos++] = '/'; }
                for (int ch = 0; ch < (int)parts[k].len; ch++) {
                    wc_buf[wpos++] = parts[k][ch];
                }
            }
            log::debug("      try WILDCARD key='%s' value='%s'", c.key, (String)wc_buf[:wpos]);
            params[*count] = { .key = c.key, .value = (String)wc_buf[:wpos] };
            (*count)++;
            *out = c.handler;
            return true;
        }
    }

    log::debug("      -> no children matched");
    return false;
}

fn bool match_linear_segments(String[] route_parts, int ri, String[] req_parts, int pi,
                               types::Param* params, sz* count)
{
    log::debug("    linear_match ri=%d pi=%d", ri, pi);
    while (ri < (int)route_parts.len && pi < (int)req_parts.len)
    {
        String rseg = route_parts[ri];
        if (rseg.len == 0) { ri++; continue; }
        String pseg = req_parts[pi];
        if (pseg.len == 0) { pi++; continue; }

        if (rseg[0] == ':')
        {
            String rest = rseg[1..];
            String key = rest;
            bool optional = false;
            String constraint;

            if (try paren = rest.index_of("("))
            {
                if (try close = rest.index_of(")"))
                {
                    if ((int)close > (int)paren + 1)
                    {
                        constraint = rest[(int)paren + 1 .. (int)close - 1];
                    }
                    key = rest[..(int)paren - 1];
                }
            }

            if (key.len > 0 && key[key.len - 1] == '?')
            {
                optional = true;
                key = key[..key.len - 2];
            }

            log::debug("      linear param key='%s' value='%s' optional=%d", key, pseg, optional);
            if (optional)
            {
                sz saved = *count;
                if (match_linear_segments(route_parts, ri + 1, req_parts, pi, params, count)) { return true; }
                *count = saved;
                if (constraint.len > 0 && !radix::match_constraint(pseg, constraint)) { return false; }
                params[*count] = { .key = key, .value = pseg };
                (*count)++;
                ri++; pi++;
            }
            else
            {
                if (constraint.len > 0 && !radix::match_constraint(pseg, constraint)) { return false; }
                params[*count] = { .key = key, .value = pseg };
                (*count)++;
                ri++; pi++;
            }
        }
        else if (rseg[0] == '*')
        {
            String key = rseg[1..];
            char[1024] wc_buf;
            sz wpos = 0;
            for (int k = pi; k < (int)req_parts.len; k++)
            {
                if (k > pi) { wc_buf[wpos++] = '/'; }
                for (int ch = 0; ch < (int)req_parts[k].len; ch++) {
                    wc_buf[wpos++] = req_parts[k][ch];
                }
            }
            log::debug("      linear wildcard key='%s' value='%s'", key, (String)wc_buf[:wpos]);
            params[*count] = { .key = key, .value = (String)wc_buf[:wpos] };
            (*count)++;
            return true;
        }
        else
        {
            log::debug("      linear static '%s' == '%s' ?", rseg, pseg);
            if (rseg != pseg) { log::debug("        -> MISMATCH"); return false; }
            ri++; pi++;
        }
    }

    while (ri < (int)route_parts.len && route_parts[ri].len == 0) ri++;
    while (pi < (int)req_parts.len && req_parts[pi].len == 0) pi++;

    bool result = ri == (int)route_parts.len && pi == (int)req_parts.len;
    log::debug("      linear result=%d (ri=%d/%d pi=%d/%d)", result, ri, (int)route_parts.len, pi, (int)req_parts.len);
    return result;
}

fn bool radix_search(Router* r, types::HttpMethod method, String path,
                     route::HandlerFn* out, types::Param* params, sz* count)
{
    log::debug("  radix_search: %s '%s'", method_to_str(method), path);
    *count = 0;
    String[] parts = path.tsplit("/");
    bool found = match_node(r, 0, 0, parts, method, out, params, count);
    log::debug("  radix_search: %sfound", found ? "" : "not ");
    return found;
}

fn bool linear_search(Router* r, types::HttpMethod method, String path,
                      route::HandlerFn* out, types::Param* params, sz* count)
{
    log::debug("  linear_search: %s '%s' (%d routes)", method_to_str(method), path, (int)r.linear_count);
    String[] req_parts = path.tsplit("/");

    for (int i = 0; i < (int)r.linear_count; i++)
    {
        if (r.linear[i].method != method) { continue; }
        *count = 0;
        String[] route_parts = r.linear[i].path.tsplit("/");
        log::debug("    trying linear[%d]: %s '%s'", i, method_to_str(r.linear[i].method), r.linear[i].path);
        if (match_linear_segments(route_parts, 0, req_parts, 0, params, count))
        {
            log::debug("    -> linear[%d] matched", i);
            *out = r.linear[i].handler;
            return true;
        }
    }
    log::debug("  linear_search: not found");
    return false;
}

fn bool find(Router* r, types::HttpMethod method, String path,
             route::HandlerFn* out, types::Param* params, sz* count)
{
    log::debug(" find: %s '%s'", method_to_str(method), path);
    if (radix_search(r, method, path, out, params, count))
    {
        log::debug(" find: matched via radix");
        return true;
    }
    if (linear_search(r, method, path, out, params, count))
    {
        log::debug(" find: matched via linear fallback");
        return true;
    }
    log::debug(" find: NOT FOUND");
    return false;
}
