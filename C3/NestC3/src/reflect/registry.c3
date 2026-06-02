module reflect::registry;

import common::metadata;
import common::decorators;
import reflect::scanner;
import di::container;

// Get all controllers registered in metadata
// Define ControllerInfo/RouteInfo/ParamInfo locally if not available from scanner
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

fn ControllerInfo[] get_controllers(ControllerInfo[] out, sz* count)
{
    String[128] controller_types;
    sz controller_count = 0;
    
    metadata::get_types_with_metadata(metadata::METADATA_KEY_CONTROLLER, controller_types, &controller_count);
    
    *count = 0;
    for (sz i = 0; i < controller_count; i++)
    {
        ControllerMetadata* meta = (ControllerMetadata*)metadata::get_metadata(controller_types[i], metadata::METADATA_KEY_CONTROLLER);
        if (meta != null && *count < 32)
        {
            ControllerInfo info;
            info.name = controller_types[i];
            info.path = meta.path;
            out[*count] = info;
            (*count)++;
        }
    }
    
    return out;
}

// Get all routes for a specific controller
fn RouteInfo[] get_routes(String controller_type_id, RouteInfo[] out, sz* count)
{
    // Note: This is a simplified implementation
    // In a real implementation, we'd need to store routes per controller
    // For now, we return empty as routes need better tracking
    *count = 0;
    return out;
}

// Get all parameter metadata for a function
fn ParamInfo[] get_params(String function_id, ParamInfo[] out, sz* count)
{
    ParamMetadata* meta = (ParamMetadata*)metadata::get_metadata(function_id, metadata::METADATA_KEY_PARAM);
    
    *count = 0;
    if (meta != null && *count < 256)
    {
        ParamInfo param;
        param.route = function_id;
        param.key = meta.key;
        param.type = meta.type;
        out[*count] = param;
        (*count)++;
    }
    
    return out;
}

// Get all providers registered in metadata
fn Provider[] get_providers(Provider[] out, sz* count)
{
    String[128] provider_types;
    sz provider_count = 0;
    
    metadata::get_types_with_metadata(metadata::METADATA_KEY_INJECTABLE, provider_types, &provider_count);
    
    *count = 0;
    for (sz i = 0; i < provider_count; i++)
    {
        InjectableMetadata* meta = (InjectableMetadata*)metadata::get_metadata(provider_types[i], metadata::METADATA_KEY_INJECTABLE);
        if (meta != null && meta.is_injectable && *count < 128)
        {
            Provider provider;
            provider.token = provider_types[i];
            provider.type = di::container::ProviderType.CLASS;
            provider.scope = di::container::Scope.SINGLETON;
            provider.provider = null; // Would need actual class reference
            provider.instance = null;
            out[*count] = provider;
            (*count)++;
        }
    }
    
    return out;
}

// Check if a type is marked as a controller
fn bool is_controller(String type_id)
{
    return metadata::has_metadata(type_id, metadata::METADATA_KEY_CONTROLLER);
}

// Check if a type is marked as injectable
fn bool is_injectable(String type_id)
{
    return metadata::has_metadata(type_id, metadata::METADATA_KEY_INJECTABLE);
}

// Get controller metadata
fn ControllerMetadata* get_controller_metadata(String type_id)
{
    return (ControllerMetadata*)metadata::get_metadata(type_id, metadata::METADATA_KEY_CONTROLLER);
}

// Get route metadata
fn RouteMetadata* get_route_metadata(String type_id)
{
    return (RouteMetadata*)metadata::get_metadata(type_id, metadata::METADATA_KEY_ROUTE);
}

// Get injectable metadata
fn InjectableMetadata* get_injectable_metadata(String type_id)
{
    return (InjectableMetadata*)metadata::get_metadata(type_id, metadata::METADATA_KEY_INJECTABLE);
}
