module examples::users_service;

import std::io;

struct User
{
    int id;
    String name;
    String email;
}

struct UsersService
{
    User[100] users;
    sz user_count;
}

fn UsersService create_users_service()
{
    UsersService service;
    service.user_count = 0;
    
    // Initialize with some sample users
    service.users[0].id = 1;
    service.users[0].name = "John Doe";
    service.users[0].email = "john@example.com";
    
    service.users[1].id = 2;
    service.users[1].name = "Jane Smith";
    service.users[1].email = "jane@example.com";
    
    service.users[2].id = 3;
    service.users[2].name = "Bob Johnson";
    service.users[2].email = "bob@example.com";
    
    service.user_count = 3;
    
    return service;
}

fn User* find_all(UsersService* service)
{
    return service.users;
}

fn sz get_user_count(UsersService* service)
{
    return service.user_count;
}

fn User* find_one(UsersService* service, int id)
{
    for (sz i = 0; i < service.user_count; i++)
    {
        if (service.users[i].id == id)
        {
            return &service.users[i];
        }
    }
    return null;
}

fn void create_user(UsersService* service, String name, String email)
{
    if (service.user_count >= 100) return;
    
    service.users[service.user_count].id = (int)service.user_count + 1;
    service.users[service.user_count].name = name;
    service.users[service.user_count].email = email;
    service.user_count++;
}

fn void delete_user(UsersService* service, int id)
{
    for (sz i = 0; i < service.user_count; i++)
    {
        if (service.users[i].id == id)
        {
            // Remove user by shifting
            for (sz j = i; j < service.user_count - 1; j++)
            {
                service.users[j] = service.users[j + 1];
            }
            service.user_count--;
            return;
        }
    }
}
