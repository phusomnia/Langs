module reflect::scanner;

import common::metadata;
import common::decorators;

struct ControllerInfo
{
    String name;
    String path;
}

struct RouteInfo
{
    String controller;
    String method;
    String path;
    String handler;
}

struct ParamInfo
{
    String route;
    String key;
    String type;
}

struct ScanResult
{
    ControllerInfo[32] controllers;
    sz controller_count;
    RouteInfo[128] routes;
    sz route_count;
    ParamInfo[256] params;
    sz param_count;
}

fn ScanResult init_scan()
{
    ScanResult result;
    result.controller_count = 0;
    result.route_count = 0;
    result.param_count = 0;
    return result;
}

fn void add_controller(ScanResult* result, String name, String path)
{
    if (result.controller_count >= 32) return;
    result.controllers[result.controller_count].name = name;
    result.controllers[result.controller_count].path = path;
    result.controller_count++;
}

fn void add_route(ScanResult* result, String controller, String method, String path, String handler)
{
    if (result.route_count >= 128) return;
    result.routes[result.route_count].controller = controller;
    result.routes[result.route_count].method = method;
    result.routes[result.route_count].path = path;
    result.routes[result.route_count].handler = handler;
    result.route_count++;
}

fn void add_param(ScanResult* result, String route, String key, String type)
{
    if (result.param_count >= 256) return;
    result.params[result.param_count].route = route;
    result.params[result.param_count].key = key;
    result.params[result.param_count].type = type;
    result.param_count++;
}
