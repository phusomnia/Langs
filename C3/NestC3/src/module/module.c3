module modules;

import controller::controller;
import di::container;
import reflect::registry;
import router::auto_register;
import core::app;

struct ModuleMetadata
{
    controller::Controller[32] controllers;
    sz controller_count;
    void*[32] providers;
    sz provider_count;
    ModuleMetadata*[16] imports;
    sz import_count;
    void*[16] exports;
    sz export_count;
}

struct Module
{
    ModuleMetadata metadata;
    di::container::DIContainer container;
    App* app;
}

fn Module init_module()
{
    Module mod;
    mod.metadata.controller_count = 0;
    mod.metadata.provider_count = 0;
    mod.metadata.import_count = 0;
    mod.metadata.export_count = 0;
    mod.container = container::init_container();
    mod.app = null;
    return mod;
}

fn void add_controller(Module* mod, controller::Controller controller)
{
    if (mod.metadata.controller_count >= 32) return;
    mod.metadata.controllers[mod.metadata.controller_count] = controller;
    mod.metadata.controller_count++;
}

fn void add_provider(Module* mod, void* provider, String token)
{
    if (mod.metadata.provider_count >= 32) return;
    container::register_class(&mod.container, token, provider);
    mod.metadata.providers[mod.metadata.provider_count] = provider;
    mod.metadata.provider_count++;
}

fn void add_import(Module* mod, ModuleMetadata* imported)
{
    if (mod.metadata.import_count >= 16) return;
    mod.metadata.imports[mod.metadata.import_count] = imported;
    mod.metadata.import_count++;
}

fn void add_export(Module* mod, void* provider)
{
    if (mod.metadata.export_count >= 16) return;
    mod.metadata.exports[mod.metadata.export_count] = provider;
    mod.metadata.export_count++;
}

// Initialize module with dependency injection
fn void init_module_providers(Module* mod)
{
    // Register all providers in the container
    di::container::Provider[128] providers;
    sz provider_count = 0;
    
    reflect::registry::get_providers(providers, &provider_count);
    
    for (sz i = 0; i < provider_count; i++)
    {
        if (!container::has_provider(&mod.container, providers[i].token))
        {
            container::register_class(&mod.container, providers[i].token, providers[i].provider, providers[i].scope);
        }
    }
}

// Register controllers with the app
fn void register_module_controllers(Module* mod, App* app)
{
    mod.app = app;
    
    for (sz i = 0; i < mod.metadata.controller_count; i++)
    {
        auto_register::register_controller_routes(app, mod.metadata.controllers[i], &mod.container);
    }
}

// Bootstrap a module
fn Module bootstrap(Module* mod, App* app)
{
    // Initialize providers
    init_module_providers(mod);
    
    // Register controllers
    register_module_controllers(mod, app);
    
    return *mod;
}

// Listen on a port (convenience method)
fn void listen(Module* mod, int port)
{
    if (mod.app != null)
    {
        app::listen(mod.app, port);
    }
}

