module common::decorators;

import common::metadata;

struct ControllerMetadata
{
    String path;
}

struct RouteMetadata
{
    String method;
    String path;
}

struct ParamMetadata
{
    String key;
    String type;
}

struct InjectableMetadata
{
    bool is_injectable;
}

// Store the current type being decorated (needs to be set when decorator is used)
// In a real implementation, this would be handled by compile-time macros
String current_type_id = "__current__";

fn void set_current_type(String type_id)
{
    current_type_id = type_id;
}

fn void controller(String path)
{
    // Allocate on heap: in C3 there's no sizeof operator exposed in this dialect,
    // so allocate by taking address of a temporary and copying, or simply use
    // a small helper allocation via malloc and zero the memory by size of the
    // struct fields. For simplicity, allocate a ControllerMetadata on the heap
    // by creating it with new (if supported) or using malloc(1) and assign fields.
    ControllerMetadata* meta = (ControllerMetadata*)malloc(1);
    meta.path = path;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_CONTROLLER, (void*)meta);
}

fn void get(String path)
{
    RouteMetadata* meta = (RouteMetadata*)malloc(1);
    meta.method = "GET";
    meta.path = path;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_ROUTE, (void*)meta);
}

fn void post(String path)
{
    RouteMetadata* meta = (RouteMetadata*)malloc(1);
    meta.method = "POST";
    meta.path = path;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_ROUTE, (void*)meta);
}

fn void put(String path)
{
    RouteMetadata* meta = (RouteMetadata*)malloc(1);
    meta.method = "PUT";
    meta.path = path;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_ROUTE, (void*)meta);
}

fn void delete(String path)
{
    RouteMetadata* meta = (RouteMetadata*)malloc(1);
    meta.method = "DELETE";
    meta.path = path;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_ROUTE, (void*)meta);
}

fn void patch(String path)
{
    RouteMetadata* meta = (RouteMetadata*)malloc(1);
    meta.method = "PATCH";
    meta.path = path;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_ROUTE, (void*)meta);
}

fn void param(String key, String type)
{
    ParamMetadata* meta = (ParamMetadata*)malloc(1);
    meta.key = key;
    meta.type = type;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_PARAM, (void*)meta);
}

fn void body()
{
    ParamMetadata* meta = (ParamMetadata*)malloc(1);
    meta.key = "body";
    meta.type = "body";
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_PARAM, (void*)meta);
}

fn void query(String key)
{
    ParamMetadata* meta = (ParamMetadata*)malloc(1);
    meta.key = key;
    meta.type = "query";
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_PARAM, (void*)meta);
}

fn void injectable()
{
    InjectableMetadata* meta = (InjectableMetadata*)malloc(1);
    meta.is_injectable = true;
    metadata::set_metadata(current_type_id, metadata::METADATA_KEY_INJECTABLE, (void*)meta);
}

// Provider decorator for services
fn void provide()
{
    injectable();
}
