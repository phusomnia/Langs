module http::headers;

struct Header
{
    String key;
    String value;
}

struct HeaderMap
{
    Header[] items;
}

fn void header_set(HeaderMap* map, String key, String value)
{
    int len = (int)map.items.len;
    for (int i = 0; i < len; i++)
    {
        if (map.items[i].key == key)
        {
            map.items[i].value = value;
            return;
        }
    }
    usz idx = map.items.len;
    Header[] new_items = mem::new_array(Header, (sz)(idx + 1));
    if (idx > 0) mem::copy(new_items.ptr, map.items.ptr, (sz)(idx * Header::size));
    new_items[idx] = { .key = key, .value = value };
    map.items = new_items;
}

fn String header_get(HeaderMap* map, String key)
{
    int len = (int)map.items.len;
    for (int i = 0; i < len; i++)
    {
        if (map.items[i].key == key) return map.items[i].value;
    }
    return "";
}