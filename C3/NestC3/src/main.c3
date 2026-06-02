module src;

import core::context;
import core::app;
import http::response;
import http::types;
import core::log;
import std::io;
// Example modules are optional for a minimal build — comment out if not present
// import examples::users_controller;
// import examples::users_service;
import controller::controller;
import modules;
import common::metadata;
import common::decorators;

struct BufData { char[1024] buf; sz written; }

fn void? buf_write(void* data, char c)
{
    BufData* b = data;
    if (b.written >= 1024) return io::BUFFER_EXCEEDED~;
    b.buf[b.written++] = c;
}

fn void write_response(context::Context* ctx, types::StatusCode code, String a, String b)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("%s%s", a, b) !!;
    response::text(ctx, code, (String)bd.buf[:bd.written]);
}

fn void get_root(context::Context* ctx)
{
    response::text(ctx, types::StatusCode.OK, "Hello from NestC3!");
}

fn void user_by_id(context::Context* ctx)
{
    if (try id = ctx.param("id"))
    {
        write_response(ctx, types::StatusCode.OK, "User: ", id);
    }
    else
    {
        response::text(ctx, types::StatusCode.BAD_REQUEST, "Missing id");
    }
}

fn void get_files(context::Context* ctx)
{
    if (try path = ctx.param("path"))
    {
        write_response(ctx, types::StatusCode.OK, "File: ", path);
    }
    else
    {
        response::text(ctx, types::StatusCode.OK, "File: (root)");
    }
}

fn void get_posts(context::Context* ctx)
{
    if (try slug = ctx.param("slug"))
    {
        write_response(ctx, types::StatusCode.OK, "Post: ", slug);
    }
    else
    {
        response::text(ctx, types::StatusCode.OK, "Posts index");
    }
}

// Example: Module-based approach with DI (Phase 3)
fn void main_with_modules()
{
    io::printf("=== NestC3 Phase 3: Module & Decorator Example ===\n");
    
    // Initialize metadata system
    metadata::init_metadata();
    
    // Create app
    App app = app::create();
    
    // If example services/controllers are available they can be wired here.
    // The example code is commented out so the project can build without examples.
    /*
    // Create UsersService
    users_service::UsersService service = users_service::create_users_service();
    
    // Create UsersController with injected service
    users_controller::UsersController controller = users_controller::create_users_controller(&service);
    
    // Create controller definition
    controller::Controller users_ctrl = controller::init_controller("/users", &controller);
    
    // Create module
    modules::Module mod = modules::init_module();
    modules::add_controller(&mod, users_ctrl);
    
    // Bootstrap module
    modules::bootstrap(&mod, &app);
    */
    
    // Register routes manually (in real phase 3, this would be automatic via decorators)
    // Example controllers are optional; manual registrations commented out when examples
    // are not included in the build.
    // app::get(&app, "/users", &users_controller::get_users_index);
    // app::get(&app, "/users/:id", &users_controller::get_user_by_id);
    // app::post(&app, "/users", &users_controller::create_user);
    
    io::printf("Listening on port 8080\n");
    app::listen(&app, 8080);
}

// Example: Classic manual route registration (backward compatible)
fn void main_classic()
{
    io::printf("=== NestC3: Classic Route Registration ===\n");
    
    App app = app::create();
    app::get(&app, "/", &get_root);
    app::get(&app, "/users/:id", &user_by_id);
    app::get(&app, "/files/*path", &get_files);
    app::get(&app, "/posts/:slug?", &get_posts);
    
    io::printf("Listening on port 8080\n");
    app::listen(&app, 8080);
}

fn void main()
{
    // Default to classic example
    // To use modules, uncomment the line below and comment out main_classic()
    main_classic();
    
    // Uncomment for Phase 3 example:
    // main_with_modules();
}
