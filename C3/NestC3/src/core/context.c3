module core::context;

import http::request;
import http::response;
import http::types;
import core::socket;

struct Context {
    request::Request req;
    response::Response res;
    void* app_data;
    socket::Socket* client;
    types::Param[types::MAX_PARAMS] params;
    sz params_count;
}

fn String? Context.param(&self, String key)
{
    for (int i = 0; i < (int)self.params_count; i++)
    {
        if (self.params[i].key == key)
        {
            String? result = self.params[i].value;
            return result;
        }
    }
    String? result;
    return result;
}
