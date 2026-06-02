module router::node;
import core::context;
import router::layer;

enum NodeType
{
    STATIC,
    PARAM,
    WILDCARD
}

struct Node 
{
    String segment;
    NodeType type;
    Node*[] children;
    HandlerFn handler;
    String param_name;
}
