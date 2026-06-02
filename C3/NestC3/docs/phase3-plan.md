# Phase 3: NestJS-like Architecture

## Overview
Transform NestC3 into a NestJS-inspired framework with controllers, dependency injection, automatic route registration, and a reflection-based metadata system.

## Goals
- Implement controller pattern with decorator-based routing
- Build dependency injection container
- Create reflection engine for AST scanning
- Enable automatic route registration
- Establish magical runtime metadata system

## Architecture

### 1. Decorator System & Metadata Architecture

#### Metadata Storage
- Global metadata registry for storing decorator information
- Type-safe metadata keys for different decorator types
- Metadata attached to types, functions, and parameters

#### Decorator Types
```
@Controller(path)
@Get(path)
@Post(path)
@Put(path)
@Delete(path)
@Patch(path)
@Param(key)
@Body()
@Query(key)
@Header(key, value)
@UseGuard(guard)
@UseInterceptor(interceptor)
@Injectable()
```

#### Implementation Structure
```
src/
├── common/
│   ├── decorators.c3      # Decorator macros/annotations
│   ├── metadata.c3        # Metadata storage and retrieval
│   └── reflect.c3         # Reflection utilities
```

### 2. Reflection Engine & AST Scanning

#### AST Scanner
- Parse C3 source files at compile time
- Extract type information, function signatures, and decorators
- Build metadata graph of controllers and their routes

#### Reflection API
```c3
// Get all controllers
fn Controller[] get_controllers()

// Get routes for a controller
fn Route[] get_routes(Controller controller)

// Get parameter metadata
fn ParamMetadata[] get_params(Function handler)

// Get dependency injection metadata
fn Provider[] get_providers()
```

#### Implementation
```
src/
├── reflect/
│   ├── scanner.c3         # AST scanner implementation
│   ├── metadata.c3        # Metadata extraction
│   └── registry.c3        # Global metadata registry
```

### 3. Controller System

#### Controller Base Class
```c3
struct Controller {
    String path;
    void* instance;
}
```

#### Controller Decorator
```c3
@Controller("/users")
class UsersController {
    @Get()
    fn void index(Context* ctx) { ... }
    
    @Get("/:id")
    fn void show(Context* ctx) { ... }
}
```

#### Implementation
```
src/
├── controller/
│   ├── controller.c3      # Controller base class
│   └── decorators.c3      # Controller-specific decorators
```

### 4. Dependency Injection Container

#### Container Architecture
```c3
struct DIContainer {
    Provider[] providers;
    void*[string] instances;
}
```

#### Provider Types
- **Class providers**: `@Injectable()` classes
- **Value providers**: Direct value injection
- **Factory providers**: Factory functions
- **Existing providers**: Aliases to existing providers

#### Injection Tokens
```c3
@Inject(TOKEN)
fn void handler(Service service) { ... }
```

#### Scope Management
- Singleton (default)
- Request-scoped
- Transient

#### Implementation
```
src/
├── di/
│   ├── container.c3       # DI container implementation
│   ├── provider.c3        # Provider types and metadata
│   ├── injector.c3        # Dependency injection logic
│   └── scope.c3           # Scope management
```

### 5. Automatic Route Registration

#### Route Discovery
- Scan all controllers via reflection
- Extract route metadata from decorators
- Build route table automatically

#### Route Registration Process
```
1. Scan AST for @Controller decorated classes
2. For each controller, scan for @Get, @Post, etc. decorated methods
3. Extract parameter metadata (@Param, @Body, @Query)
4. Register routes with hybrid router
5. Wire up DI container for handler dependencies
```

#### Implementation
```
src/
├── router/
│   └── auto_register.c3   # Automatic route registration
```

### 6. Module System

#### Module Structure
```c3
@Module({
    controllers: [UsersController, PostsController],
    providers: [UsersService, PostsService],
    imports: [AuthModule],
    exports: [UsersService]
})
class UsersModule { }
```

#### Module Metadata
- Controllers to register
- Providers to inject
- Imported modules
- Exported providers

#### Implementation
```
src/
├── module/
│   ├── module.c3          # Module base class
│   └── metadata.c3        # Module metadata
```

## Implementation Steps

### Step 1: Metadata System Foundation
- Implement metadata storage registry
- Create type-safe metadata keys
- Build metadata attachment API

### Step 2: Decorator Implementation
- Implement @Controller decorator
- Implement HTTP method decorators (@Get, @Post, etc.)
- Implement parameter decorators (@Param, @Body, @Query)
- Implement @Injectable decorator

### Step 3: Reflection Engine
- Build AST scanner for C3 source files
- Implement metadata extraction from AST
- Create reflection API for querying metadata

### Step 4: DI Container
- Implement provider registration
- Build dependency resolution logic
- Add scope management (singleton, request, transient)
- Implement circular dependency detection

### Step 5: Controller System
- Create controller base class
- Implement controller instantiation with DI
- Add controller lifecycle hooks

### Step 6: Automatic Route Registration
- Build route discovery from controllers
- Implement automatic router registration
- Integrate with existing hybrid router
- Add parameter binding from metadata

### Step 7: Module System
- Implement @Module decorator
- Build module discovery and registration
- Add module dependency resolution
- Implement provider exports/imports

### Step 8: Integration & Testing
- Integrate all components
- Create example application
- Write comprehensive tests
- Performance optimization

## Example Usage

### Before (Current)
```c3
fn void main() {
    App app = app::create();
    app::get(&app, "/users/:id", &user_by_id);
    app::listen(&app, 8080);
}
```

### After (Phase 3)
```c3
@Controller("/users")
@Injectable()
class UsersController {
    @Inject()
    UsersService usersService;

    @Get()
    fn void index(Context* ctx) {
        response::json(ctx, usersService.findAll());
    }

    @Get("/:id")
    fn void show(Context* ctx) {
        if (try id = ctx.param("id")) {
            response::json(ctx, usersService.findOne(id));
        }
    }

    @Post()
    fn void create(Context* ctx) {
        CreateUserDto dto = ctx.body<CreateUserDto>();
        response::json(ctx, usersService.create(dto));
    }
}

@Module({
    controllers: [UsersController],
    providers: [UsersService]
})
class AppModule { }

fn void main() {
    AppModule module = bootstrap(AppModule);
    module.listen(8080);
}
```

## Testing Strategy

### Unit Tests

#### Metadata System Tests
```c3
// Test metadata storage and retrieval
fn void test_metadata_storage()
fn void test_metadata_key_safety()
fn void test_decorator_attachment()
```

#### Reflection Engine Tests
```c3
// Test AST scanning
fn void test_ast_scanner_basic()
fn void test_controller_extraction()
fn void test_route_metadata_extraction()
fn void test_parameter_metadata_extraction()
```

#### DI Container Tests
```c3
// Test dependency injection
fn void test_singleton_provider()
fn void test_transient_provider()
fn void test_request_scoped_provider()
fn void test_circular_dependency_detection()
fn void test_provider_resolution()
fn void test_factory_provider()
fn void test_value_provider()
```

#### Controller System Tests
```c3
// Test controller instantiation
fn void test_controller_creation()
fn void test_controller_di_injection()
fn void test_controller_lifecycle()
```

### Integration Tests

#### Automatic Route Registration Tests
```c3
// Test route discovery and registration
fn void test_auto_route_registration()
fn void test_controller_route_mapping()
fn void test_parameter_binding()
fn void test_decorator_combination()
```

#### Module System Tests
```c3
// Test module organization
fn void test_module_registration()
fn void test_module_imports()
fn void test_module_exports()
fn void test_module_provider_sharing()
```

#### End-to-End Tests
```c3
// Test full application flow
fn void test_full_controller_flow()
fn void test_di_in_request_context()
fn void test_module_bootstrap()
fn void test_backward_compatibility()
```

### Test Structure
```
src/
├── tests/
│   ├── unit/
│   │   ├── metadata_test.c3
│   │   ├── reflection_test.c3
│   │   ├── di_test.c3
│   │   └── controller_test.c3
│   ├── integration/
│   │   ├── auto_register_test.c3
│   │   └── module_test.c3
│   └── e2e/
│       └── app_test.c3
```

### Test Coverage Goals
- Metadata system: 90%+ coverage
- Reflection engine: 85%+ coverage
- DI container: 95%+ coverage
- Controller system: 90%+ coverage
- Automatic registration: 85%+ coverage
- Module system: 85%+ coverage

### Performance Tests
```c3
// Benchmark DI container lookup
fn void benchmark_di_lookup()

// Benchmark route registration
fn void benchmark_route_registration()

// Benchmark AST scanning
fn void benchmark_ast_scanning()

// Memory leak detection
fn void test_memory_leaks()
```

### Test Utilities
```c3
// Test helpers
struct TestContext {
    DIContainer container;
    App app;
}

fn TestContext create_test_context()
fn void cleanup_test_context(TestContext* ctx)
fn MockService create_mock_service()
```

## Technical Challenges

### C3 Language Limitations
- Decorators may need to be implemented as compile-time macros
- Reflection capabilities may be limited
- May need to use code generation for some features

### Performance Considerations
- AST scanning overhead at startup
- DI container lookup performance
- Metadata storage efficiency

### Compatibility
- Maintain backward compatibility with manual route registration
- Ensure hybrid router continues to work with both approaches

## Success Criteria
- Controllers with decorators work correctly
- DI container resolves dependencies properly
- Automatic route registration functional
- Module system organizes code effectively
- Performance comparable to manual registration
- Clean, NestJS-like API
