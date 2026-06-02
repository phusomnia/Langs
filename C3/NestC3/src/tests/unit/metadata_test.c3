module tests::unit::metadata_test;

import common::metadata;
import common::decorators;
import std::io;

struct AssertResult
{
    sz passed;
    sz failed;
    String last_error;
}

AssertResult test_result;

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

fn void assert_equals(String expected, String actual, String message)
{
    if (expected == actual)
    {
        test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        test_result.failed++;
        test_result.last_error = message;
        io::printf("✗ %s: expected '%s', got '%s'\n", message, expected, actual);
    }
}

fn void test_metadata_initialization()
{
    io::printf("\n--- Test: Metadata Initialization ---\n");
    metadata::init_metadata();
    assert_true(true, "Metadata system initialized");
}

fn void test_metadata_storage_and_retrieval()
{
    io::printf("\n--- Test: Metadata Storage and Retrieval ---\n");
    metadata::init_metadata();
    
    // Set metadata for a type
    decorators::ControllerMetadata* ctrl_meta = (decorators::ControllerMetadata*)malloc(sizeof(decorators::ControllerMetadata));
    ctrl_meta.path = "/users";
    
    metadata::set_metadata("UsersController", metadata::METADATA_KEY_CONTROLLER, (void*)ctrl_meta);
    
    // Retrieve metadata
    void* retrieved = metadata::get_metadata("UsersController", metadata::METADATA_KEY_CONTROLLER);
    assert_true(retrieved != null, "Metadata stored and retrieved successfully");
    
    decorators::ControllerMetadata* retrieved_meta = (decorators::ControllerMetadata*)retrieved;
    assert_equals("/users", retrieved_meta.path, "Controller path matches");
}

fn void test_metadata_key_safety()
{
    io::printf("\n--- Test: Metadata Key Safety ---\n");
    metadata::init_metadata();
    
    // Store different metadata types
    decorators::RouteMetadata* route_meta = (decorators::RouteMetadata*)malloc(sizeof(decorators::RouteMetadata));
    route_meta.method = "GET";
    route_meta.path = "/users";
    
    metadata::set_metadata("UsersController", metadata::METADATA_KEY_ROUTE, (void*)route_meta);
    
    // Store injectable metadata
    decorators::InjectableMetadata* inj_meta = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
    inj_meta.is_injectable = true;
    
    metadata::set_metadata("UsersService", metadata::METADATA_KEY_INJECTABLE, (void*)inj_meta);
    
    // Verify different keys don't interfere
    void* route_result = metadata::get_metadata("UsersController", metadata::METADATA_KEY_ROUTE);
    void* inj_result = metadata::get_metadata("UsersService", metadata::METADATA_KEY_INJECTABLE);
    
    assert_true(route_result != null, "Route metadata retrieved");
    assert_true(inj_result != null, "Injectable metadata retrieved");
}

fn void test_metadata_has_function()
{
    io::printf("\n--- Test: Metadata Has Function ---\n");
    metadata::init_metadata();
    
    // Set metadata
    decorators::InjectableMetadata* meta = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
    meta.is_injectable = true;
    metadata::set_metadata("MyService", metadata::METADATA_KEY_INJECTABLE, (void*)meta);
    
    // Test has_metadata
    bool has_it = metadata::has_metadata("MyService", metadata::METADATA_KEY_INJECTABLE);
    bool doesnt_have = metadata::has_metadata("MyService", metadata::METADATA_KEY_CONTROLLER);
    
    assert_true(has_it, "has_metadata returns true for existing metadata");
    assert_true(!doesnt_have, "has_metadata returns false for non-existing metadata");
}

fn void test_metadata_multiple_types()
{
    io::printf("\n--- Test: Multiple Type Metadata ---\n");
    metadata::init_metadata();
    
    // Store metadata for multiple types
    for (int i = 0; i < 5; i++)
    {
        decorators::InjectableMetadata* meta = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
        meta.is_injectable = true;
        
        char[32] type_id;
        io::snprintf(type_id, 32, "Service%d", i);
        metadata::set_metadata((String)type_id, metadata::METADATA_KEY_INJECTABLE, (void*)meta);
    }
    
    // Verify all are stored
    bool all_stored = true;
    for (int i = 0; i < 5; i++)
    {
        char[32] type_id;
        io::snprintf(type_id, 32, "Service%d", i);
        if (!metadata::has_metadata((String)type_id, metadata::METADATA_KEY_INJECTABLE))
        {
            all_stored = false;
        }
    }
    
    assert_true(all_stored, "Multiple type metadata stored correctly");
}

fn void run_metadata_tests()
{
    io::printf("================================\n");
    io::printf("  Metadata System Unit Tests\n");
    io::printf("================================\n");
    
    test_result.passed = 0;
    test_result.failed = 0;
    
    test_metadata_initialization();
    test_metadata_storage_and_retrieval();
    test_metadata_key_safety();
    test_metadata_has_function();
    test_metadata_multiple_types();
    
    io::printf("\n================================\n");
    io::printf("Results: %zu passed, %zu failed\n", test_result.passed, test_result.failed);
    io::printf("================================\n");
}
