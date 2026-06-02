module examples::users_controller;

import core::context;
import http::response;
import http::types;
import common::decorators;
import examples::users_service;
import std::io;

struct CreateUserDto
{
    String name;
    String email;
}

// UsersController with dependency injection
// Note: In a real implementation, this would use macros for decorators
struct UsersController
{
    users_service::UsersService* service;
}

fn UsersController create_users_controller(users_service::UsersService* service)
{
    UsersController controller;
    controller.service = service;
    return controller;
}

// @Get() - List all users
fn void users_index(context::Context* ctx, UsersController* controller)
{
    io::printf("GET /users\n");
    
    sz count = users_service::get_user_count(controller.service);
    
    // Format: Simple text response
    char[512] buf;
    io::Formatter f;
    
    // In a real implementation, would return JSON
    response::text(ctx, types::StatusCode.OK, "Users list");
}

// @Get("/:id") - Get user by ID
fn void users_show(context::Context* ctx, UsersController* controller)
{
    if (try id_str = ctx.param("id"))
    {
        int id = (int)id_str[0] - 48;  // Simple string to int conversion
        users_service::User* user = users_service::find_one(controller.service, id);
        
        if (user != null)
        {
            response::text(ctx, types::StatusCode.OK, "User found");
        }
        else
        {
            response::text(ctx, types::StatusCode.NOT_FOUND, "User not found");
        }
    }
    else
    {
        response::text(ctx, types::StatusCode.BAD_REQUEST, "Missing id parameter");
    }
}

// @Post() - Create new user
fn void users_create(context::Context* ctx, UsersController* controller)
{
    // In a real implementation, would parse JSON body
    users_service::create_user(controller.service, "New User", "new@example.com");
    
    response::text(ctx, types::StatusCode.CREATED, "User created");
}

// @Delete("/:id") - Delete user
fn void users_delete(context::Context* ctx, UsersController* controller)
{
    if (try id_str = ctx.param("id"))
    {
        int id = (int)id_str[0] - 48;  // Simple string to int conversion
        users_service::delete_user(controller.service, id);
        
        response::text(ctx, types::StatusCode.NO_CONTENT, "");
    }
    else
    {
        response::text(ctx, types::StatusCode.BAD_REQUEST, "Missing id parameter");
    }
}

// Legacy functions for backward compatibility
fn void get_users_index(context::Context* ctx)
{
    response::text(ctx, types::StatusCode.OK, "Users index");
}

fn void get_user_by_id(context::Context* ctx)
{
    if (try id = ctx.param("id"))
    {
        response::text(ctx, types::StatusCode.OK, "User: " + id);
    }
    else
    {
        response::text(ctx, types::StatusCode.BAD_REQUEST, "Missing id");
    }
}

fn void create_user(context::Context* ctx)
{
    response::text(ctx, types::StatusCode.CREATED, "User created");
}
