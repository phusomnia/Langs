# Phase 3 Quick Start Guide

## Overview

NestC3 Phase 3 brings NestJS-like architecture to C3 with decorators, dependency injection, and automatic route registration.

## Installation & Setup

The Phase 3 implementation is ready to use in your NestC3 project. All components are already integrated:

```bash
# Build the project
./build.sh

# Run tests (if test runner is used in main)
./build/nestc3
```

## Basic Usage

### Option 1: Classic Manual Routes (Backward Compatible)

```c3
fn void handler(context::Context* ctx) {
    response::text(ctx, types::StatusCode.OK, "Hello!");
}

fn void main() {
    App app = app::create();
    app::get(&app, "/", &handler);
    app::listen(&app, 8080);
}
```

### Option 2: Phase 3 Module Approach

```c3
fn void main() {
    // Initialize metadata system
    metadata::init_metadata();
    
    // Create service
    MyService service = create_my_service();
    
    // Create controller with injected service
    MyController controller = create_my_controller(&service);
    
    // Create module
    Module module = init_module();
    add_controller(&module, init_controller("/api", &controller));
    
    // Bootstrap app
    App app = app::create();
    bootstrap(&module, &app);
    app::listen(&app, 8080);
}
```

## Key Components

### 1. Metadata System

Store and retrieve type information:

```c3
import common::metadata;
import common::decorators;

// Mark a type as injectable
decorators::InjectableMetadata* meta = 
    (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
meta.is_injectable = true;
metadata::set_metadata("MyService", metadata::METADATA_KEY_INJECTABLE, (void*)meta);

// Retrieve metadata
void* retrieved = metadata::get_metadata("MyService", metadata::METADATA_KEY_INJECTABLE);
```

### 2. Dependency Injection Container

Register and resolve dependencies:

```c3
import di::container;

di::container::DIContainer di = container::init_container();

// Register a service (singleton)
MyService service = create_service();
container::register_class(&di, "MyService", &service, container::Scope.SINGLETON);

// Register a value
String config_value = "some_value";
container::register_value(&di, "ConfigValue", (void*)config_value);

// Resolve
void* resolved = container::resolve(&di, "MyService");
```

### 3. Controllers with Dependency Injection

```c3
struct MyController {
    MyService* service;
}

fn MyController create_my_controller(MyService* service) {
    MyController controller;
    controller.service = service;
    return controller;
}

fn void handler(context::Context* ctx, MyController* controller) {
    // Use injected service
    MyService* svc = controller.service;
    // ... handle request
}
```

### 4. Module System

Organize code with modules:

```c3
import modules;

// Create module
Module app_module = init_module();

// Add controllers
add_controller(&app_module, my_controller);

// Add providers
add_provider(&app_module, &my_service, "MyService");

// Bootstrap
App app = app::create();
bootstrap(&app_module, &app);
```

### 5. Reflection API

Query registered types:

```c3
import reflect::registry;

// Get all controllers
reflect::registry::ControllerInfo controllers[32];
sz count = 0;
reflect::registry::get_controllers(controllers, &count);

// Get all providers
di::container::Provider providers[128];
sz provider_count = 0;
reflect::registry::get_providers(providers, &provider_count);

// Check if type is controller
if (reflect::registry::is_controller("MyController")) {
    // ...
}

// Check if type is injectable
if (reflect::registry::is_injectable("MyService")) {
    // ...
}
```

## Example: Complete Application

```c3
// service.c3
struct UserService {
    User[100] users;
    sz count;
}

fn UserService create_user_service() {
    UserService svc;
    svc.count = 0;
    return svc;
}

fn void add_user(UserService* svc, String name) {
    // Implementation...
}

// controller.c3
struct UserController {
    UserService* service;
}

fn UserController create_user_controller(UserService* svc) {
    UserController ctrl;
    ctrl.service = svc;
    return ctrl;
}

fn void list_users(context::Context* ctx, UserController* ctrl) {
    // Implementation...
    response::text(ctx, types::StatusCode.OK, "Users list");
}

// main.c3
fn void main() {
    metadata::init_metadata();
    
    // Create DI container
    di::container::DIContainer di = container::init_container();
    
    // Create and register service
    UserService service = create_user_service();
    container::register_class(&di, "UserService", &service);
    
    // Create controller
    UserController controller = create_user_controller(&service);
    
    // Create module
    Module module = init_module();
    add_controller(&module, init_controller("/users", &controller));
    
    // Create and bootstrap app
    App app = app::create();
    bootstrap(&module, &app);
    
    app::listen(&app, 8080);
}
```

## Testing

Run the comprehensive test suite:

```c3
import tests::test_runner;

fn void main() {
    tests::test_runner::run_all_tests();
}
```

This runs:
- Unit tests for metadata, DI, and reflection
- Integration tests for routes and modules
- End-to-end application tests
- Performance benchmarks

## Decorator Reference

While C3 limitations prevent true decorators, simulate them via functions:

```c3
// Controllers
decorators::controller("/users");           // Mark as controller
decorators::set_current_type("UsersController");

// HTTP Methods
decorators::get("/");                       // GET handler
decorators::post("");                       // POST handler
decorators::put("");                        // PUT handler
decorators::delete("");                     // DELETE handler
decorators::patch("");                      // PATCH handler

// Parameters
decorators::param("id", "string");          // URL parameter
decorators::query("page");                  // Query parameter
decorators::body();                         // Request body

// Services
decorators::injectable();                   // Mark as injectable
decorators::provide();                      // Provider alias
```

## Dependency Injection Scopes

```c3
// Singleton (default) - same instance always
container::register_class(&di, "Service", &svc, container::Scope.SINGLETON);

// Transient - new instance each time
container::register_class(&di, "Service", &svc, container::Scope.TRANSIENT);

// Request - per request (reserved for future use)
container::register_class(&di, "Service", &svc, container::Scope.REQUEST);
```

## Performance Tips

1. **Metadata Queries**: Cache results if querying repeatedly
2. **DI Container**: Resolve services early, reuse instances
3. **Module Bootstrap**: Do once at startup, not per-request
4. **Routes**: Automatic registration is O(n), acceptable for typical apps

## Troubleshooting

### Circular Dependencies
DI container detects circular dependencies and logs errors:
```
ERROR: Circular dependency detected for token: ServiceA
```

### Metadata Not Found
Ensure metadata::init_metadata() is called at startup:
```c3
fn void main() {
    metadata::init_metadata();  // Required!
    // ... rest of code
}
```

### Type Not Resolved
Check that the type is registered:
```c3
if (container::has_provider(&di, "MyService")) {
    void* svc = container::resolve(&di, "MyService");
} else {
    io::printf("MyService not registered\n");
}
```

## Next Steps

1. Review `PHASE3_IMPLEMENTATION.md` for detailed architecture
2. Check `src/tests/` for example usage patterns
3. Look at `src/examples/users_controller.c3` for complete example
4. Run benchmarks with `tests/performance/benchmark.c3`

## API Reference

### metadata.c3
- `init_metadata()` - Initialize system
- `set_metadata(type_id, key, value)` - Store metadata
- `get_metadata(type_id, key)` - Retrieve metadata
- `has_metadata(type_id, key)` - Check if exists
- `get_types_with_metadata(key, out, count)` - Find types

### di/container.c3
- `init_container()` - Create DI container
- `register_class()` - Register class provider
- `register_value()` - Register value provider
- `register_factory()` - Register factory provider
- `register_existing()` - Register alias
- `resolve()` - Get instance from container
- `has_provider()` - Check if provider exists
- `get_provider_count()` - Get total providers

### reflect/registry.c3
- `get_controllers()` - Get all controllers
- `get_routes()` - Get controller routes
- `get_params()` - Get parameter metadata
- `get_providers()` - Get all providers
- `is_controller()` - Check if controller
- `is_injectable()` - Check if injectable

### modules.c3
- `init_module()` - Create module
- `add_controller()` - Add controller to module
- `add_provider()` - Add provider to module
- `add_import()` - Import another module
- `add_export()` - Export provider
- `bootstrap()` - Initialize and register module
- `listen()` - Start listening (convenience)

## Support

For issues or feedback:
- Report bugs: https://github.com/anomalyco/opencode
- Check documentation: https://opencode.ai/docs
- Review source: `src/` directory

Happy coding with NestC3! 🚀
