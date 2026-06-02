module tests::test_runner;

import tests::unit::metadata_test;
import tests::unit::di_test;
import tests::unit::reflection_test;
import tests::integration::auto_register_test;
import tests::integration::module_test;
import tests::e2e::app_test;
import std::io;

fn void run_all_tests()
{
    io::printf("\n");
    io::printf("╔════════════════════════════════════════╗\n");
    io::printf("║   NestC3 Phase 3 - Complete Test Suite  ║\n");
    io::printf("╚════════════════════════════════════════╝\n");
    
    // Unit Tests
    io::printf("\n█ UNIT TESTS\n");
    metadata_test::run_metadata_tests();
    di_test::run_di_tests();
    reflection_test::run_reflection_tests();
    
    // Integration Tests
    io::printf("\n█ INTEGRATION TESTS\n");
    auto_register_test::run_auto_register_tests();
    module_test::run_module_tests();
    
    // End-to-End Tests
    io::printf("\n█ END-TO-END TESTS\n");
    app_test::run_e2e_tests();
    
    io::printf("\n");
    io::printf("╔════════════════════════════════════════╗\n");
    io::printf("║   All Tests Completed                   ║\n");
    io::printf("╚════════════════════════════════════════╝\n");
}
