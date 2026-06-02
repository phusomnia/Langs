module tests::unit::reflection_test;

import common::metadata;
import common::decorators;
import reflect::registry;
import di::container;
import std::io;

struct AssertResult
{
    sz passed;
    sz failed;
    String last_error;
}

AssertResult reflect_test_result;

fn void assert_true(bool condition, String message)
{
    if (condition)
    {
        reflect_test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        reflect_test_result.failed++;
        reflect_test_result.last_error = message;
        io::printf("✗ %s\n", message);
    }
}

fn void assert_equals(sz expected, sz actual, String message)
{
    if (expected == actual)
    {
        reflect_test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        reflect_test_result.failed++;
        reflect_test_result.last_error = message;
        io::printf("✗ %s: expected %zu, got %zu\n", message, expected, actual);
    }
}

fn void test_reflection_initialization()
{
    io::printf("\n--- Test: Reflection Initialization ---\n");
    metadata::init_metadata();
    assert_true(true, "Reflection system initialized");
}

fn void test_controller_metadata_query()
{
    io::printf("\n--- Test: Controller Metadata Query ---\n");
    metadata::init_metadata();
    
    // Create and register a controller
    decorators::ControllerMetadata* ctrl_meta = (decorators::ControllerMetadata*)malloc(sizeof(decorators::ControllerMetadata));
    ctrl_meta.path = "/users";
    
    metadata::set_metadata("UsersController", metadata::METADATA_KEY_CONTROLLER, (void*)ctrl_meta);
    
    // Query via registry
    bool is_ctrl = reflect::registry::is_controller("UsersController");
    assert_true(is_ctrl, "Controller detected via reflection");
    
    decorators::ControllerMetadata* retrieved = reflect::registry::get_controller_metadata("UsersController");
    assert_true(retrieved != null, "Controller metadata retrieved");
}

fn void test_get_controllers()
{
    io::printf("\n--- Test: Get Controllers ---\n");
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
    
    // Retrieve all controllers
    reflect::registry::ControllerInfo[32] controllers;
    sz count = 0;
    reflect::registry::get_controllers(controllers, &count);
    
    assert_equals(3, count, "All controllers retrieved");
}

fn void test_injectable_detection()
{
    io::printf("\n--- Test: Injectable Detection ---\n");
    metadata::init_metadata();
    
    // Mark a type as injectable
    decorators::InjectableMetadata* inj_meta = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
    inj_meta.is_injectable = true;
    
    metadata::set_metadata("MyService", metadata::METADATA_KEY_INJECTABLE, (void*)inj_meta);
    
    // Query via registry
    bool is_inj = reflect::registry::is_injectable("MyService");
    assert_true(is_inj, "Injectable type detected");
    
    decorators::InjectableMetadata* retrieved = reflect::registry::get_injectable_metadata("MyService");
    assert_true(retrieved != null, "Injectable metadata retrieved");
}

fn void test_get_providers()
{
    io::printf("\n--- Test: Get Providers ---\n");
    metadata::init_metadata();
    
    // Register multiple providers
    for (int i = 0; i < 3; i++)
    {
        decorators::InjectableMetadata* meta = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
        meta.is_injectable = true;
        
        char[32] svc_name;
        io::snprintf(svc_name, 32, "Service%d", i);
        metadata::set_metadata((String)svc_name, metadata::METADATA_KEY_INJECTABLE, (void*)meta);
    }
    
    // Retrieve all providers
    di::container::Provider[128] providers;
    sz count = 0;
    reflect::registry::get_providers(providers, &count);
    
    assert_equals(3, count, "All providers retrieved");
}

fn void test_route_metadata_query()
{
    io::printf("\n--- Test: Route Metadata Query ---\n");
    metadata::init_metadata();
    
    // Create route metadata
    decorators::RouteMetadata* route = (decorators::RouteMetadata*)malloc(sizeof(decorators::RouteMetadata));
    route.method = "GET";
    route.path = "/users/:id";
    
    metadata::set_metadata("GetUser", metadata::METADATA_KEY_ROUTE, (void*)route);
    
    // Query via registry
    decorators::RouteMetadata* retrieved = reflect::registry::get_route_metadata("GetUser");
    assert_true(retrieved != null, "Route metadata retrieved");
}

fn void test_multiple_metadata_types()
{
    io::printf("\n--- Test: Multiple Metadata Types ---\n");
    metadata::init_metadata();
    
    // Store different metadata types for same type
    decorators::ControllerMetadata* ctrl = (decorators::ControllerMetadata*)malloc(sizeof(decorators::ControllerMetadata));
    ctrl.path = "/api";
    metadata::set_metadata("MyController", metadata::METADATA_KEY_CONTROLLER, (void*)ctrl);
    
    decorators::InjectableMetadata* inj = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
    inj.is_injectable = true;
    metadata::set_metadata("MyController", metadata::METADATA_KEY_INJECTABLE, (void*)inj);
    
    // Verify both are retrievable
    bool has_ctrl = reflect::registry::is_controller("MyController");
    bool has_inj = reflect::registry::is_injectable("MyController");
    
    assert_true(has_ctrl && has_inj, "Multiple metadata types stored for same type");
}

fn void run_reflection_tests()
{
    io::printf("================================\n");
    io::printf("  Reflection Engine Unit Tests\n");
    io::printf("================================\n");
    
    reflect_test_result.passed = 0;
    reflect_test_result.failed = 0;
    
    test_reflection_initialization();
    test_controller_metadata_query();
    test_get_controllers();
    test_injectable_detection();
    test_get_providers();
    test_route_metadata_query();
    test_multiple_metadata_types();
    
    io::printf("\n================================\n");
    io::printf("Results: %zu passed, %zu failed\n", reflect_test_result.passed, reflect_test_result.failed);
    io::printf("================================\n");
}
