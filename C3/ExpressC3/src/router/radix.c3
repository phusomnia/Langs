module router::radix;
import router::node;
import router::layer;
import core::context;
import http::headers;

fn Node* node_new(String seg, NodeType type, HandlerFn handler)
{
    Node* n = mem::new(Node);
    n.segment = seg;
    n.type = type;
    n.handler = handler;
    n.children = {};
    n.param_name = "";
    return n;
}

fn void node_add_child(Node* parent, Node* child)
{
    usz idx = parent.children.len;
    Node*[] new_arr = mem::new_array(Node*, (sz)(idx + 1));
    if (idx > 0) mem::copy(new_arr.ptr, parent.children.ptr, (sz)(idx * Node*::size));
    new_arr[idx] = child;
    parent.children = new_arr;
}

fn NodeType segment_type(String seg)
{
    if (seg.len > 0 && seg[0] == ':') return NodeType.PARAM;
    if (seg.len > 0 && seg[0] == '*') return NodeType.WILDCARD;
    return NodeType.STATIC;
}

fn String param_name_from_seg(String seg)
{
    if (seg.len == 0) return "";
    if (seg[0] == '*')
    {
        if (seg.len == 1) return "all";
        return seg[1:seg.len - 1];
    }
    if (seg[0] == ':')
    {
        if (seg.len <= 1) return "";
        return seg[1:seg.len - 1];
    }
    return "";
}

fn void radix_insert(Node** root, String path, HandlerFn handler)
{
    if (*root == null)
    {
        *root = node_new("", NodeType.STATIC, null);
    }

    Node* node = *root;

    if (path == "/" || path.len == 0)
    {
        node.handler = handler;
        return;
    }

    usz pos = 0;
    if (path[0] == '/') pos = 1;

    while (pos < path.len)
    {
        usz seg_start = pos;
        while (pos < path.len && path[pos] != '/') pos++;
        String seg = path[seg_start:pos - seg_start];

        if (pos < path.len && path[pos] == '/') pos++;

        NodeType st = segment_type(seg);

        Node* found = null;
        for (int i = 0; i < (int)node.children.len; i++)
        {
            Node* child = node.children[i];
            if (child.type == st && child.segment == seg)
            {
                found = child;
                break;
            }
        }

        if (found == null)
        {
            found = node_new(seg, st, null);
            found.param_name = param_name_from_seg(seg);
            node_add_child(node, found);
        }

        node = found;
    }

    node.handler = handler;
}

fn Node* radix_search(Node* root, String path, HeaderMap* params)
{
    if (root == null) return null;

    if (path == "/" || path.len == 0)
    {
        return (root.handler != null) ? root : null;
    }

    Node* node = root;
    usz pos = 0;
    if (path[0] == '/') pos = 1;

    while (pos < path.len && node != null)
    {
        usz seg_start = pos;
        while (pos < path.len && path[pos] != '/') pos++;
        String seg = path[seg_start:pos - seg_start];

        if (pos < path.len && path[pos] == '/') pos++;

        Node* match = null;

        // 1. Static children (exact segment match)
        for (int i = 0; i < (int)node.children.len; i++)
        {
            Node* child = node.children[i];
            if (child.type == NodeType.STATIC && child.segment == seg)
            {
                match = child;
                break;
            }
        }

        // 2. Param children (capture segment value)
        if (match == null)
        {
            for (int i = 0; i < (int)node.children.len; i++)
            {
                Node* child = node.children[i];
                if (child.type == NodeType.PARAM)
                {
                    if (params != null && child.param_name.len > 0)
                    {
                        headers::header_set(params, child.param_name, seg);
                    }
                    match = child;
                    break;
                }
            }
        }

        // 3. Wildcard children (capture rest of path)
        if (match == null)
        {
            for (int i = 0; i < (int)node.children.len; i++)
            {
                Node* child = node.children[i];
                if (child.type == NodeType.WILDCARD)
                {
                    if (params != null && child.param_name.len > 0)
                    {
                        String wildcard_val = path[seg_start:path.len - seg_start];
                        headers::header_set(params, child.param_name, wildcard_val);
                    }
                    match = child;
                    break;
                }
            }
        }

        // Wildcard consumes everything, return immediately
        if (match != null && match.type == NodeType.WILDCARD)
        {
            return match;
        }

        node = match;
    }

    return node;
}
