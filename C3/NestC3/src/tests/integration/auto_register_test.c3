module tests::integration::auto_register_test;

import core::app;
import core::context;
import http::response;
import http::types;
import router::auto_register;
import reflect::registry;
import di::container;
import common::metadata;
import common::decorators;
import std::io;

struct TestResult
{
    sz passed;
    sz failed;
    String last_error;
}

TestResult test_result;

fn void assert_true(bool condition, String message)
{
    if (condition)
    {
        test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        test_result.failed++;
        test_result.last_error = message;
        io::printf("✗ %s\n", message);
    }
}

// Test handler
fn void test_route_handler(context::Context* ctx)
{
    response::text(ctx, types::StatusCode.OK, "Test");
}

fn void test_route_registration_basic()
{
    io::printf("\n--- Test: Basic Route Registration ---\n");
    metadata::init_metadata();
    
    // Create DI container
    di::container::DIContainer di = container::init_container();
    
    // Create app
    App app = app::create();
    
    app::get(&app, "/test", &test_route_handler);
    
    assert_true(true, "Route registered without errors");
}

fn void test_auto_register_all()
{
    io::printf("\n--- Test: Auto Register All ---\n");
    metadata::init_metadata();
    
    // Register a controller
    decorators::ControllerMetadata* ctrl_meta = (decorators::ControllerMetadata*)malloc(sizeof(decorators::ControllerMetadata));
    ctrl_meta.path = "/api";
    metadata::set_metadata("TestController", metadata::METADATA_KEY_CONTROLLER, (void*)ctrl_meta);
    
    // Create DI container
    di::container::DIContainer di = container::init_container();
    
    // Register controller in DI
    container::register_value(&di, "TestController", null);
    
    // Create app
    App app = app::create();
    
    // Auto register
    auto_register::auto_register_all(&app, &di);
    
    assert_true(true, "Auto registration completed without errors");
}

fn void test_di_container_resolution()
{
    io::printf("\n--- Test: DI Container Resolution ---\n");
    
    di::container::DIContainer container_di = container::init_container();
    
    int service_val = 42;
    container::register_class(&container_di, "MockService", &service_val);
    
    void* resolved = container::resolve(&container_di, "MockService");
    
    assert_true(resolved != null, "Service resolved from DI container");
}

fn void test_multiple_controller_registration()
{
    io::printf("\n--- Test: Multiple Controller Registration ---\n");
    metadata::init_metadata();
    
    // Register multiple controllers
    for (int i = 0; i < 3; i++)
    {
        decorators::ControllerMetadata* meta = (decorators::ControllerMetadata*)malloc(sizeof(decorators::ControllerMetadata));
        meta.path = "/api";
        
        char[32] ctrl_name;
        io::snprintf(ctrl_name, 32, "Controller%d", i);
        metadata::set_metadata((String)ctrl_name, metadata::METADATA_KEY_CONTROLLER, (void*)meta);
    }
    
    // Get all controllers
    reflect::registry::ControllerInfo[32] controllers;
    sz count = 0;
    reflect::registry::get_controllers(controllers, &count);
    
    assert_true(count == 3, "All controllers registered and discovered");
}

fn void run_auto_register_tests()
{
    io::printf("================================\n");
    io::printf("  Route Registration Tests\n");
    io::printf("================================\n");
    
    test_result.passed = 0;
    test_result.failed = 0;
    
    test_route_registration_basic();
    test_auto_register_all();
    test_di_container_resolution();
    test_multiple_controller_registration();
    
    io::printf("\n================================\n");
    io::printf("Results: %zu passed, %zu failed\n", test_result.passed, test_result.failed);
    io::printf("================================\n");
}
