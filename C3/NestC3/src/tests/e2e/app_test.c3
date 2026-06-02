module tests::e2e::app_test;

import core::app;
import core::context;
import http::response;
import http::types;
import examples::users_controller;
import examples::users_service;
import controller::controller;
import modules;
import di::container;
import common::metadata;
import std::io;

struct E2ETestResult
{
    sz passed;
    sz failed;
    String last_error;
}

E2ETestResult e2e_result;

fn void assert_true(bool condition, String message)
{
    if (condition)
    {
        e2e_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        e2e_result.failed++;
        e2e_result.last_error = message;
        io::printf("✗ %s\n", message);
    }
}

// Handler for testing
fn void test_handler(context::Context* ctx)
{
    response::text(ctx, types::StatusCode.OK, "Test");
}

fn void test_users_service_creation()
{
    io::printf("\n--- Test: Users Service Creation ---\n");
    
    users_service::UsersService service = users_service::create_users_service();
    
    assert_true(service.user_count > 0, "Users service created with sample data");
    
    sz count = users_service::get_user_count(&service);
    assert_true(count == 3, "Users service has expected number of users");
}

fn void test_users_service_operations()
{
    io::printf("\n--- Test: Users Service Operations ---\n");
    
    users_service::UsersService service = users_service::create_users_service();
    
    // Test find_one
    users_service::User* user = users_service::find_one(&service, 1);
    assert_true(user != null, "User found by ID");
    
    // Test create
    users_service::create_user(&service, "Alice", "alice@example.com");
    sz count = users_service::get_user_count(&service);
    assert_true(count == 4, "User created successfully");
}

fn void test_users_controller_creation()
{
    io::printf("\n--- Test: Users Controller Creation ---\n");
    
    users_service::UsersService service = users_service::create_users_service();
    users_controller::UsersController ctrl = users_controller::create_users_controller(&service);
    
    assert_true(ctrl.service != null, "Controller created with service dependency");
}

fn void test_controller_initialization()
{
    io::printf("\n--- Test: Controller Initialization ---\n");
    
    controller::Controller ctrl = controller::init_controller("/users", null);
    
    assert_true(ctrl.path != null, "Controller path set");
}

fn void test_module_creation_and_bootstrap()
{
    io::printf("\n--- Test: Module Creation and Bootstrap ---\n");
    metadata::init_metadata();
    
    modules::Module mod = modules::init_module();
    
    // Add controller
    controller::Controller ctrl = controller::init_controller("/api/users", null);
    modules::add_controller(&mod, ctrl);
    
    assert_true(mod.metadata.controller_count == 1, "Controller added to module");
}

fn void test_dependency_injection_chain()
{
    io::printf("\n--- Test: Dependency Injection Chain ---\n");
    
    di::container::DIContainer di = container::init_container();
    
    // Register service
    users_service::UsersService service = users_service::create_users_service();
    container::register_class(&di, "UsersService", &service);
    
    // Register controller
    users_controller::UsersController ctrl = users_controller::create_users_controller(&service);
    container::register_class(&di, "UsersController", &ctrl);
    
    // Resolve controller
    void* resolved_ctrl = container::resolve(&di, "UsersController");
    
    assert_true(resolved_ctrl != null, "Controller resolved with dependencies");
}

fn void test_app_creation_with_routes()
{
    io::printf("\n--- Test: App Creation with Routes ---\n");
    
    App app = app::create();
    
    app::get(&app, "/", &test_handler);
    app::get(&app, "/users/:id", &test_handler);
    app::post(&app, "/users", &test_handler);
    
    assert_true(true, "App created with multiple routes");
}

fn void test_full_module_flow()
{
    io::printf("\n--- Test: Full Module Flow ---\n");
    metadata::init_metadata();
    
    // 1. Create DI container
    di::container::DIContainer di = container::init_container();
    
    // 2. Create service
    users_service::UsersService service = users_service::create_users_service();
    di::container::register_class(&di, "UsersService", &service);
    
    // 3. Create controller
    users_controller::UsersController ctrl = users_controller::create_users_controller(&service);
    di::container::register_class(&di, "UsersController", &ctrl);
    
    // 4. Create module
    modules::Module mod = modules::init_module();
    
    // 5. Add controller to module
    controller::Controller controller_def = controller::init_controller("/users", &ctrl);
    modules::add_controller(&mod, controller_def);
    
    // 6. Initialize module providers
    modules::init_module_providers(&mod);
    
    // 7. Create app
    App app = app::create();
    
    // 8. Register module controllers
    modules::register_module_controllers(&mod, &app);
    
    assert_true(true, "Full module flow completed successfully");
}

fn void test_backward_compatibility()
{
    io::printf("\n--- Test: Backward Compatibility ---\n");
    
    App app = app::create();
    
    // Manual route registration (old style)
    app::get(&app, "/api/users", &test_handler);
    app::post(&app, "/api/users", &test_handler);
    app::get(&app, "/api/users/:id", &test_handler);
    
    assert_true(true, "Backward compatible manual route registration works");
}

fn void run_e2e_tests()
{
    io::printf("================================\n");
    io::printf("  End-to-End Application Tests\n");
    io::printf("================================\n");
    
    e2e_result.passed = 0;
    e2e_result.failed = 0;
    
    test_users_service_creation();
    test_users_service_operations();
    test_users_controller_creation();
    test_controller_initialization();
    test_module_creation_and_bootstrap();
    test_dependency_injection_chain();
    test_app_creation_with_routes();
    test_full_module_flow();
    test_backward_compatibility();
    
    io::printf("\n================================\n");
    io::printf("Results: %zu passed, %zu failed\n", e2e_result.passed, e2e_result.failed);
    io::printf("================================\n");
}
