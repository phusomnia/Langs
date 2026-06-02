module tests::unit::di_test;

import di::container;
import std::io;

struct TestService
{
    String name;
    int id;
}

struct TestDependency
{
    String value;
}

struct AssertResult
{
    sz passed;
    sz failed;
    String last_error;
}

AssertResult di_test_result;

fn void assert_true(bool condition, String message)
{
    if (condition)
    {
        di_test_result.passed++;
        io::printf("✓ %s\n", message);
    }
    else
    {
        di_test_result.failed++;
        di_test_result.last_error = message;
        io::printf("✗ %s\n", message);
    }
}

fn TestService create_test_service()
{
    TestService svc;
    svc.name = "TestService";
    svc.id = 1;
    return svc;
}

fn TestDependency create_test_dependency()
{
    TestDependency dep;
    dep.value = "dependency";
    return dep;
}

fn void test_container_initialization()
{
    io::printf("\n--- Test: Container Initialization ---\n");
    di::container::DIContainer container = container::init_container();
    
    assert_true(container.provider_count == 0, "Container initialized with 0 providers");
}

fn void test_register_class()
{
    io::printf("\n--- Test: Register Class Provider ---\n");
    di::container::DIContainer container = container::init_container();
    
    TestService svc = create_test_service();
    container::register_class(&container, "TestService", &svc);
    
    assert_true(container.provider_count == 1, "Provider count incremented");
    assert_true(container::has_provider(&container, "TestService"), "Provider registered with correct token");
}

fn void test_register_value()
{
    io::printf("\n--- Test: Register Value Provider ---\n");
    di::container::DIContainer container = container::init_container();
    
    String value = "test_value";
    container::register_value(&container, "StringValue", (void*)value);
    
    void* resolved = container::resolve(&container, "StringValue");
    String resolved_value = (String)resolved;
    
    assert_true(resolved != null, "Value provider resolved");
    assert_true(resolved_value == value, "Resolved value matches original");
}

fn void test_singleton_scope()
{
    io::printf("\n--- Test: Singleton Scope ---\n");
    di::container::DIContainer container = container::init_container();
    
    TestService svc = create_test_service();
    container::register_class(&container, "TestService", &svc, container::Scope.SINGLETON);
    
    void* resolved1 = container::resolve(&container, "TestService");
    void* resolved2 = container::resolve(&container, "TestService");
    
    assert_true(resolved1 == resolved2, "Singleton returns same instance");
}

fn void test_transient_scope()
{
    io::printf("\n--- Test: Transient Scope ---\n");
    di::container::DIContainer container = container::init_container();
    
    TestService svc = create_test_service();
    container::register_class(&container, "TestService", &svc, container::Scope.TRANSIENT);
    
    void* resolved = container::resolve(&container, "TestService");
    
    assert_true(resolved != null, "Transient provider resolved");
}

fn void test_resolve_nonexistent()
{
    io::printf("\n--- Test: Resolve Non-existent Provider ---\n");
    di::container::DIContainer container = container::init_container();
    
    void* resolved = container::resolve(&container, "NonExistent");
    
    assert_true(resolved == null, "Non-existent provider returns null");
}

fn void test_register_factory()
{
    io::printf("\n--- Test: Factory Provider ---\n");
    di::container::DIContainer container = container::init_container();
    
    TestService svc = create_test_service();
    container::register_factory(&container, "TestServiceFactory", &svc);
    
    assert_true(container::has_provider(&container, "TestServiceFactory"), "Factory provider registered");
}

fn void test_register_existing()
{
    io::printf("\n--- Test: Existing Provider (Alias) ---\n");
    di::container::DIContainer container = container::init_container();
    
    String value = "test_value";
    container::register_value(&container, "OriginalToken", (void*)value);
    container::register_existing(&container, "AliasToken", "OriginalToken");
    
    void* resolved_alias = container::resolve(&container, "AliasToken");
    
    assert_true(resolved_alias != null, "Alias provider resolved");
}

fn void test_circular_dependency_detection()
{
    io::printf("\n--- Test: Circular Dependency Detection ---\n");
    di::container::DIContainer container = container::init_container();
    
    // Manually set up a circular dependency scenario
    container.resolution_stack[0] = "ServiceA";
    container.stack_depth = 1;
    
    bool is_circular = container::has_circular_dependency(&container, "ServiceA");
    
    assert_true(is_circular, "Circular dependency detected");
    
    bool not_circular = container::has_circular_dependency(&container, "ServiceB");
    
    assert_true(!not_circular, "Non-circular dependency not flagged");
}

fn void test_multiple_providers()
{
    io::printf("\n--- Test: Multiple Providers ---\n");
    di::container::DIContainer container = container::init_container();
    
    // Register multiple providers
    String val1 = "value1";
    String val2 = "value2";
    String val3 = "value3";
    
    container::register_value(&container, "Value1", (void*)val1);
    container::register_value(&container, "Value2", (void*)val2);
    container::register_value(&container, "Value3", (void*)val3);
    
    assert_true(container.provider_count == 3, "All providers registered");
    
    void* res1 = container::resolve(&container, "Value1");
    void* res2 = container::resolve(&container, "Value2");
    void* res3 = container::resolve(&container, "Value3");
    
    assert_true(res1 != null && res2 != null && res3 != null, "All providers resolved");
}

fn void run_di_tests()
{
    io::printf("================================\n");
    io::printf("  DI Container Unit Tests\n");
    io::printf("================================\n");
    
    di_test_result.passed = 0;
    di_test_result.failed = 0;
    
    test_container_initialization();
    test_register_class();
    test_register_value();
    test_singleton_scope();
    test_transient_scope();
    test_resolve_nonexistent();
    test_register_factory();
    test_register_existing();
    test_circular_dependency_detection();
    test_multiple_providers();
    
    io::printf("\n================================\n");
    io::printf("Results: %zu passed, %zu failed\n", di_test_result.passed, di_test_result.failed);
    io::printf("================================\n");
}
