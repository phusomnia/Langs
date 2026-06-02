module tests::performance::benchmark;

import di::container;
import common::metadata;
import reflect::registry;
import router::auto_register;
import std::io;

struct BenchmarkResult
{
    String name;
    sz iterations;
    long total_time_ms;
    double avg_time_us;
}

// Simple timing utilities
fn long current_time_ms()
{
    // Note: In a real implementation, would use actual system time
    // For now, this is a placeholder
    return 0;
}

fn void benchmark_di_lookup()
{
    io::printf("\n--- Benchmark: DI Container Lookup ---\n");
    
    di::container::DIContainer container = container::init_container();
    
    // Register multiple services
    for (int i = 0; i < 100; i++)
    {
        char[32] token;
        io::snprintf(token, 32, "Service%d", i);
        container::register_value(&container, (String)token, null);
    }
    
    // Warm up
    for (int i = 0; i < 100; i++)
    {
        container::resolve(&container, "Service50");
    }
    
    // Benchmark lookups
    sz iterations = 10000;
    for (sz i = 0; i < iterations; i++)
    {
        container::resolve(&container, "Service50");
    }
    
    io::printf("  - Performed %zu lookups\n", iterations);
    io::printf("  - Average lookup time: O(n) where n = provider count\n");
}

fn void benchmark_metadata_lookup()
{
    io::printf("\n--- Benchmark: Metadata Lookup ---\n");
    metadata::init_metadata();
    
    // Store metadata for multiple types
    for (int i = 0; i < 50; i++)
    {
        char[32] type_id;
        io::snprintf(type_id, 32, "Type%d", i);
        
        common::decorators::InjectableMetadata* meta = 
            (common::decorators::InjectableMetadata*)malloc(sizeof(common::decorators::InjectableMetadata));
        meta.is_injectable = true;
        metadata::set_metadata((String)type_id, metadata::METADATA_KEY_INJECTABLE, (void*)meta);
    }
    
    // Benchmark lookups
    sz iterations = 10000;
    for (sz i = 0; i < iterations; i++)
    {
        metadata::has_metadata("Type25", metadata::METADATA_KEY_INJECTABLE);
    }
    
    io::printf("  - Performed %zu metadata lookups\n", iterations);
    io::printf("  - Average metadata lookup time: O(m*n) where m = types, n = keys per type\n");
}

fn void benchmark_reflection()
{
    io::printf("\n--- Benchmark: Reflection Operations ---\n");
    metadata::init_metadata();
    
    // Register controllers
    for (int i = 0; i < 20; i++)
    {
        char[32] ctrl_name;
        io::snprintf(ctrl_name, 32, "Controller%d", i);
        
        common::decorators::ControllerMetadata* meta = 
            (common::decorators::ControllerMetadata*)malloc(sizeof(common::decorators::ControllerMetadata));
        meta.path = "/api";
        metadata::set_metadata((String)ctrl_name, metadata::METADATA_KEY_CONTROLLER, (void*)meta);
    }
    
    // Benchmark get_controllers
    reflect::registry::ControllerInfo[32] controllers;
    sz count = 0;
    
    sz iterations = 1000;
    for (sz i = 0; i < iterations; i++)
    {
        reflect::registry::get_controllers(controllers, &count);
    }
    
    io::printf("  - Performed %zu reflection scans\n", iterations);
    io::printf("  - Found %zu controllers per scan\n", count);
}

fn void benchmark_di_resolution_depth()
{
    io::printf("\n--- Benchmark: DI Resolution with Dependencies ---\n");
    
    di::container::DIContainer container = container::init_container();
    
    // Create a simple dependency chain
    container::register_value(&container, "ServiceA", null);
    container::register_existing(&container, "ServiceB", "ServiceA");
    container::register_existing(&container, "ServiceC", "ServiceB");
    container::register_existing(&container, "ServiceD", "ServiceC");
    
    // Benchmark resolution
    sz iterations = 10000;
    for (sz i = 0; i < iterations; i++)
    {
        container::resolve(&container, "ServiceD");
    }
    
    io::printf("  - Performed %zu resolution chains (depth=4)\n", iterations);
}

fn void run_benchmarks()
{
    io::printf("\n╔════════════════════════════════════════╗\n");
    io::printf("║   NestC3 Performance Benchmarks         ║\n");
    io::printf("╚════════════════════════════════════════╝\n");
    
    benchmark_di_lookup();
    benchmark_metadata_lookup();
    benchmark_reflection();
    benchmark_di_resolution_depth();
    
    io::printf("\n═════════════════════════════════════════\n");
    io::printf("  Performance benchmarking complete\n");
    io::printf("═════════════════════════════════════════\n");
    io::printf("\n  Note: For detailed timing, compile with\n");
    io::printf("  actual system time functions and higher\n");
    io::printf("  resolution clock support.\n");
}
