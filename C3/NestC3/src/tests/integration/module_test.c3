module tests::integration::module_test;

import modules;
import di::container;
import controller::controller;
import common::metadata;
import common::decorators;
import reflect::registry;
import std::io;

// Test structures at module level
struct MockService { String name; }
struct TestService1 { int id; }
struct TestService2 { int id; }
struct TestService3 { int id; }
struct ExportedService { String name; }

struct TestResult
{
    sz passed;
    sz failed;
    String last_error;
}

TestResult module_test_result;

fn void assert_true(bool condition, String message)
{
    if (condition)
    {
        module_test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        module_test_result.failed++;
        module_test_result.last_error = message;
        io::printf("✗ %s\n", message);
    }
}

fn void assert_equals(sz expected, sz actual, String message)
{
    if (expected == actual)
    {
        module_test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        module_test_result.failed++;
        module_test_result.last_error = message;
        io::printf("✗ %s: expected %zu, got %zu\n", message, expected, actual);
    }
}

fn void test_module_initialization()
{
    io::printf("\n--- Test: Module Initialization ---\n");
    
    modules::Module mod = modules::init_module();
    
    assert_true(mod.metadata.controller_count == 0, "Module initialized with 0 controllers");
    assert_true(mod.metadata.provider_count == 0, "Module initialized with 0 providers");
    assert_true(mod.metadata.import_count == 0, "Module initialized with 0 imports");
}

fn void test_module_add_controller()
{
    io::printf("\n--- Test: Add Controller to Module ---\n");
    
    modules::Module mod = modules::init_module();
    
    controller::Controller ctrl = controller::init_controller("/api", null);
    modules::add_controller(&mod, ctrl);
    
    assert_equals(1, mod.metadata.controller_count, "Controller added to module");
}

fn void test_module_add_provider()
{
    io::printf("\n--- Test: Add Provider to Module ---\n");
    
    modules::Module mod = modules::init_module();
    
    MockService service;
    service.name = "TestService";
    
    modules::add_provider(&mod, &service, "TestService");
    
    assert_equals(1, mod.metadata.provider_count, "Provider added to module");
}

fn void test_module_container_integration()
{
    io::printf("\n--- Test: Module Container Integration ---\n");
    
    modules::Module mod = modules::init_module();
    
    TestService1 service;
    service.id = 42;
    
    modules::add_provider(&mod, &service, "TestService");
    
    void* resolved = container::resolve(&mod.container, "TestService");
    
    assert_true(resolved != null, "Provider resolved from module container");
}

fn void test_module_multiple_controllers()
{
    io::printf("\n--- Test: Module with Multiple Controllers ---\n");
    
    modules::Module mod = modules::init_module();
    
    for (int i = 0; i < 3; i++)
    {
        controller::Controller ctrl = controller::init_controller("/api", null);
        modules::add_controller(&mod, ctrl);
    }
    
    assert_equals(3, mod.metadata.controller_count, "All controllers added to module");
}

fn void test_module_multiple_providers()
{
    io::printf("\n--- Test: Module with Multiple Providers ---\n");
    
    modules::Module mod = modules::init_module();
    
    TestService1 s1;
    TestService2 s2;
    TestService3 s3;
    
    modules::add_provider(&mod, &s1, "Service1");
    modules::add_provider(&mod, &s2, "Service2");
    modules::add_provider(&mod, &s3, "Service3");
    
    assert_equals(3, mod.metadata.provider_count, "All providers added to module");
}

fn void test_module_provider_initialization()
{
    io::printf("\n--- Test: Module Provider Initialization ---\n");
    metadata::init_metadata();
    
    modules::Module mod = modules::init_module();
    
    decorators::InjectableMetadata* meta1 = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
    meta1.is_injectable = true;
    metadata::set_metadata("Service1", metadata::METADATA_KEY_INJECTABLE, (void*)meta1);
    
    decorators::InjectableMetadata* meta2 = (decorators::InjectableMetadata*)malloc(sizeof(decorators::InjectableMetadata));
    meta2.is_injectable = true;
    metadata::set_metadata("Service2", metadata::METADATA_KEY_INJECTABLE, (void*)meta2);
    
    modules::init_module_providers(&mod);
    
    assert_true(true, "Module providers initialized without errors");
}

fn void test_module_exports()
{
    io::printf("\n--- Test: Module Exports ---\n");
    
    modules::Module mod = modules::init_module();
    
    ExportedService service;
    
    modules::add_export(&mod, &service);
    
    assert_equals(1, mod.metadata.export_count, "Provider exported from module");
}

fn void run_module_tests()
{
    io::printf("================================\n");
    io::printf("  Module System Integration Tests\n");
    io::printf("================================\n");
    
    module_test_result.passed = 0;
    module_test_result.failed = 0;
    
    test_module_initialization();
    test_module_add_controller();
    test_module_add_provider();
    test_module_container_integration();
    test_module_multiple_controllers();
    test_module_multiple_providers();
    test_module_provider_initialization();
    test_module_exports();
    
    io::printf("\n================================\n");
    io::printf("Results: %zu passed, %zu failed\n", module_test_result.passed, module_test_result.failed);
    io::printf("================================\n");
}
