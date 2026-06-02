module src::tests;

import router::router;
import router::radix;
import router::route;
import http::types;
import http::request;
import core::context;
import std::core::test;

fn void test_classify_static() @test
{
    String part; String key; String constraint;
    radix::SegmentType st = router::classify_segment("hello", &part, &key, &constraint);
    test::eq(st, radix::SegmentType.STATIC);
    test::eq(part, "hello");
}

fn void test_classify_param() @test
{
    String part; String key; String constraint;
    radix::SegmentType st = router::classify_segment(":id", &part, &key, &constraint);
    test::eq(st, radix::SegmentType.PARAM);
    test::eq(part, "id");
    test::eq(key, "id");
}

fn void test_classify_param_optional() @test
{
    String part; String key; String constraint;
    radix::SegmentType st = router::classify_segment(":slug?", &part, &key, &constraint);
    test::eq(st, radix::SegmentType.PARAM_OPT);
    test::eq(part, "slug");
    test::eq(key, "slug");
}

fn void test_classify_wildcard() @test
{
    String part; String key; String constraint;
    radix::SegmentType st = router::classify_segment("*path", &part, &key, &constraint);
    test::eq(st, radix::SegmentType.WILDCARD);
    test::eq(part, "path");
    test::eq(key, "path");
}

fn void test_classify_param_constraint() @test
{
    String part; String key; String constraint;
    radix::SegmentType st = router::classify_segment(":id(\\d+)", &part, &key, &constraint);
    test::eq(st, radix::SegmentType.GLOB);
    test::eq(part, "id");
    test::eq(key, "id");
    test::eq(constraint, "\\d+");
}

fn void test_string_index_of_paren() @test
{
    String s = "id(\\d+)";
    if (try idx_opt = s.index_of("("))
    {
        int idx = (int)idx_opt;
        test::eq(idx, 2);
        if (try close_opt = s.index_of(")"))
        {
            int close = (int)close_opt;
            test::eq(close, 6);
            // C3 uses INCLUSIVE ranges: [..n] includes index n
            String constraint = s[idx + 1 .. close - 1];
            test::eq(constraint, "\\d+");
            String sliced = s[..idx - 1];
            test::eq(sliced, "id");
        }
        else { assert(false, "should find )"); }
    }
    else { assert(false, "should find ("); }
}

fn void test_char_literal_comparison() @test
{
    String s = "slug?";
    assert(s[4] == '?', "char at [4] should be '?'");
    test::eq(s.len, 5);
    assert(s[s.len - 1] == '?', "last char should be '?'");
}

fn void test_constraint_digits() @test
{
    test::eq(radix::match_constraint("123", "\\d+"), true);
    test::eq(radix::match_constraint("abc", "\\d+"), false);
    test::eq(radix::match_constraint("12a", "\\d+"), false);
}

fn void test_constraint_word() @test
{
    test::eq(radix::match_constraint("hello", "\\w+"), true);
    test::eq(radix::match_constraint("hello123", "\\w+"), true);
    test::eq(radix::match_constraint("hello-world", "\\w+"), false);
}

fn void test_constraint_dot() @test
{
    test::eq(radix::match_constraint("a", "."), true);
    test::eq(radix::match_constraint("ab", "."), false);
    test::eq(radix::match_constraint("", "."), false);
}

fn void test_constraint_literal() @test
{
    test::eq(radix::match_constraint("abc", "abc"), true);
    test::eq(radix::match_constraint("abx", "abc"), false);
}

fn void dummy_handler(context::Context* ctx) { (void)ctx; }
fn void get_handler(context::Context* ctx) { (void)ctx; }
fn void post_handler(context::Context* ctx) { (void)ctx; }

fn void test_router_add_and_find_static() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/hello", &dummy_handler);
    bool found = router::find(&r, types::HttpMethod.GET, "/hello", &h, &params, &count);
    test::eq(found, true);
    test::eq((void*)h, (void*)&dummy_handler);
}

fn void test_router_find_param() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/users/:id", &dummy_handler);
    bool found = router::find(&r, types::HttpMethod.GET, "/users/42", &h, &params, &count);
    test::eq(found, true);
    test::eq(count, 1);
    test::eq(params[0].key, "id");
    test::eq(params[0].value, "42");
}

fn void test_router_find_wildcard() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/files/*path", &dummy_handler);
    bool found = router::find(&r, types::HttpMethod.GET, "/files/a/b/c", &h, &params, &count);
    test::eq(found, true);
    test::eq(count, 1);
    test::eq(params[0].key, "path");
    test::eq(params[0].value, "a/b/c");
}

fn void test_router_find_optional_param() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/posts/:slug?", &dummy_handler);

    bool found_with = router::find(&r, types::HttpMethod.GET, "/posts/hello", &h, &params, &count);
    test::eq(found_with, true);
    test::eq(count, 1);
    test::eq(params[0].key, "slug");
    test::eq(params[0].value, "hello");

    bool found_without = router::find(&r, types::HttpMethod.GET, "/posts", &h, &params, &count);
    test::eq(found_without, true);
    test::eq(count, 0);
}

fn void test_router_not_found() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/hello", &dummy_handler);

    bool found = router::find(&r, types::HttpMethod.GET, "/world", &h, &params, &count);
    test::eq(found, false);
}

fn void test_router_method_match() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/item", &get_handler);
    router::add(&r, types::HttpMethod.POST, "/item", &post_handler);

    bool found_get = router::find(&r, types::HttpMethod.GET, "/item", &h, &params, &count);
    test::eq(found_get, true);

    bool found_post = router::find(&r, types::HttpMethod.POST, "/item", &h, &params, &count);
    test::eq(found_post, true);

    bool found_delete = router::find(&r, types::HttpMethod.DELETE, "/item", &h, &params, &count);
    test::eq(found_delete, false);
}

fn void test_constraint_digit_dot() @test
{
    test::eq(radix::match_constraint("5", "\\d"), true);
    test::eq(radix::match_constraint("a", "\\d"), false);
}

// Linear search fallback (when radix tree is full)
fn void test_linear_search_fallback() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/hello/world", &dummy_handler);
    router::add(&r, types::HttpMethod.GET, "/users/:id", &dummy_handler);
    router::add(&r, types::HttpMethod.POST, "/data", &dummy_handler);

    bool found = router::find(&r, types::HttpMethod.GET, "/hello/world", &h, &params, &count);
    test::eq(found, true);

    bool found_param = router::find(&r, types::HttpMethod.GET, "/users/42", &h, &params, &count);
    test::eq(found_param, true);
    test::eq(count, 1);
    test::eq(params[0].key, "id");
    test::eq(params[0].value, "42");

    bool found_mismatch = router::find(&r, types::HttpMethod.POST, "/hello/world", &h, &params, &count);
    test::eq(found_mismatch, false);
}

fn void test_linear_search_wildcard() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/static/*filepath", &dummy_handler);

    bool found = router::find(&r, types::HttpMethod.GET, "/static/css/style.css", &h, &params, &count);
    test::eq(found, true);
    test::eq(count, 1);
    test::eq(params[0].key, "filepath");
    test::eq(params[0].value, "css/style.css");
}

fn void test_multi_param_route() @test
{
    router::Router r = router::init();
    route::HandlerFn h;
    types::Param[types::MAX_PARAMS] params;
    sz count;

    router::add(&r, types::HttpMethod.GET, "/users/:uid/posts/:pid", &dummy_handler);

    bool found = router::find(&r, types::HttpMethod.GET, "/users/123/posts/456", &h, &params, &count);
    test::eq(found, true);
    test::eq(count, 2);
    test::eq(params[0].key, "uid");
    test::eq(params[0].value, "123");
    test::eq(params[1].key, "pid");
    test::eq(params[1].value, "456");
}

fn void test_parse_method_str() @test
{
    test::eq(request::parse_method_str("GET"), types::HttpMethod.GET);
    test::eq(request::parse_method_str("POST"), types::HttpMethod.POST);
    test::eq(request::parse_method_str("PUT"), types::HttpMethod.PUT);
    test::eq(request::parse_method_str("DELETE"), types::HttpMethod.DELETE);
    test::eq(request::parse_method_str("PATCH"), types::HttpMethod.PATCH);
    test::eq(request::parse_method_str("HEAD"), types::HttpMethod.HEAD);
    test::eq(request::parse_method_str("OPTIONS"), types::HttpMethod.OPTIONS);
}

fn void test_status_code_reason() @test
{
    types::StatusCode ok = types::StatusCode.OK;
    types::StatusCode nf = types::StatusCode.NOT_FOUND;
    types::StatusCode ise = types::StatusCode.INTERNAL_SERVER_ERROR;
    types::StatusCode br = types::StatusCode.BAD_REQUEST;
    test::eq(types::StatusCode.reason(&ok), "OK");
    test::eq(types::StatusCode.reason(&nf), "Not Found");
    test::eq(types::StatusCode.reason(&ise), "Internal Server Error");
    test::eq(types::StatusCode.reason(&br), "Bad Request");
}

fn void test_status_code_code() @test
{
    test::eq(types::StatusCode.OK.code, 200);
    test::eq(types::StatusCode.NOT_FOUND.code, 404);
    test::eq(types::StatusCode.INTERNAL_SERVER_ERROR.code, 500);
}
