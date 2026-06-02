module router::auto_register;

import core::app;
import core::context;
import router::route;
import http::types;
import reflect::scanner;
import reflect::registry;
import controller::controller;
import di::container;
import std::io;

struct RouteRegistration
{
    String method;
    String path;
    route::HandlerFn handler;
}

// Wrapper to bind controller instance with handler
fn void create_handler_wrapper(context::Context* ctx, void* controller_instance)
{
    // This would be called with the actual controller instance
    // and would invoke the appropriate method
}

fn void register_controller_routes(App* app, Controller controller, di::container::DIContainer* di)
{
    // Get controller metadata
    if (controller.instance == null)
    {
        io::printf("ERROR: Controller instance is null\n");
        return;
    }
    
    // In a real implementation, would scan controller methods for route decorators
    // For now, this is a placeholder
    io::printf("Registering routes for controller at path: %s\n", controller.path);
}

fn void auto_register_controllers(App* app, Controller[] controllers, sz count, di::container::DIContainer* di)
{
    for (sz i = 0; i < count; i++)
    {
        register_controller_routes(app, controllers[i], di);
    }
}

// Advanced: Register a specific route with DI container support
fn void register_route_with_di(
    App* app,
    String method,
    String path,
    route::HandlerFn handler,
    String controller_token,
    di::container::DIContainer* di
)
{
    // Resolve controller from DI container
    void* controller = container::resolve(di, controller_token);
    
    if (controller == null)
    {
        io::printf("ERROR: Could not resolve controller: %s\n", controller_token);
        return;
    }
    
    // Register the route
    if (method == "GET")
    {
        app::get(app, path, handler);
    }
    else if (method == "POST")
    {
        app::post(app, path, handler);
    }
    else if (method == "PUT")
    {
        app::put(app, path, handler);
    }
    else if (method == "DELETE")
    {
        app::delete(app, path, handler);
    }
    else if (method == "PATCH")
    {
        app::patch(app, path, handler);
    }
    
    io::printf("Registered %s %s with DI container\n", method, path);
}

// Register all controllers discovered via reflection
fn void auto_register_all(App* app, di::container::DIContainer* di)
{
    reflect::registry::ControllerInfo[32] controllers;
    sz controller_count = 0;
    
    reflect::registry::get_controllers(controllers, &controller_count);
    
    io::printf("Found %zu controllers to register\n", controller_count);
    
    for (sz i = 0; i < controller_count; i++)
    {
        io::printf("  - %s at path %s\n", controllers[i].name, controllers[i].path);
        
        // Resolve controller from DI
        void* controller_instance = container::resolve(di, controllers[i].name);
        
        if (controller_instance != null)
        {
            Controller controller = {
                .path = controllers[i].path,
                .instance = controller_instance
            };
            
            register_controller_routes(app, controller, di);
        }
    }
}

