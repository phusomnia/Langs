module router::matcher;

struct ParamMap
{
    Param[] items;
}

struct Param
{
    String key;
    String value;
}
