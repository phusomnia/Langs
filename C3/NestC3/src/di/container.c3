module di::container;

import std::io;

enum ProviderType
{
    CLASS,
    VALUE,
    FACTORY,
    EXISTING
}

enum Scope
{
    SINGLETON,
    REQUEST,
    TRANSIENT
}

struct Provider
{
    String token;
    ProviderType type;
    Scope scope;
    void* provider;
    void* instance;
    String* depends_on;  // For circular dependency detection
    sz dependency_count;
}

struct DIContainer
{
    Provider[128] providers;
    sz provider_count;
    String[128] resolution_stack;  // For circular dependency detection
    sz stack_depth;
}

fn DIContainer init_container()
{
    DIContainer container;
    container.provider_count = 0;
    container.stack_depth = 0;
    return container;
}

fn void register_class(DIContainer* container, String token, void* provider, Scope scope = Scope.SINGLETON)
{
    if (container.provider_count >= 128) return;
    
    // Check if already registered
    for (sz i = 0; i < container.provider_count; i++)
    {
        if (container.providers[i].token == token)
        {
            return;
        }
    }
    
    container.providers[container.provider_count].token = token;
    container.providers[container.provider_count].type = ProviderType.CLASS;
    container.providers[container.provider_count].scope = scope;
    container.providers[container.provider_count].provider = provider;
    container.providers[container.provider_count].instance = null;
    container.providers[container.provider_count].dependency_count = 0;
    container.provider_count++;
}

fn void register_value(DIContainer* container, String token, void* value)
{
    if (container.provider_count >= 128) return;
    
    // Check if already registered
    for (sz i = 0; i < container.provider_count; i++)
    {
        if (container.providers[i].token == token)
        {
            container.providers[i].instance = value;
            return;
        }
    }
    
    container.providers[container.provider_count].token = token;
    container.providers[container.provider_count].type = ProviderType.VALUE;
    container.providers[container.provider_count].scope = Scope.SINGLETON;
    container.providers[container.provider_count].provider = null;
    container.providers[container.provider_count].instance = value;
    container.providers[container.provider_count].dependency_count = 0;
    container.provider_count++;
}

// Register a factory provider
fn void register_factory(DIContainer* container, String token, void* factory_fn, Scope scope = Scope.TRANSIENT)
{
    if (container.provider_count >= 128) return;
    
    // Check if already registered
    for (sz i = 0; i < container.provider_count; i++)
    {
        if (container.providers[i].token == token)
        {
            return;
        }
    }
    
    container.providers[container.provider_count].token = token;
    container.providers[container.provider_count].type = ProviderType.FACTORY;
    container.providers[container.provider_count].scope = scope;
    container.providers[container.provider_count].provider = factory_fn;
    container.providers[container.provider_count].instance = null;
    container.providers[container.provider_count].dependency_count = 0;
    container.provider_count++;
}

// Register an existing provider (alias)
fn void register_existing(DIContainer* container, String token, String existing_token)
{
    if (container.provider_count >= 128) return;
    
    // Check if already registered
    for (sz i = 0; i < container.provider_count; i++)
    {
        if (container.providers[i].token == token)
        {
            return;
        }
    }
    
    container.providers[container.provider_count].token = token;
    container.providers[container.provider_count].type = ProviderType.EXISTING;
    container.providers[container.provider_count].scope = Scope.SINGLETON;
    container.providers[container.provider_count].provider = (void*)existing_token;
    container.providers[container.provider_count].instance = null;
    container.providers[container.provider_count].dependency_count = 0;
    container.provider_count++;
}

// Check for circular dependencies
fn bool has_circular_dependency(DIContainer* container, String token)
{
    for (sz i = 0; i < container.stack_depth; i++)
    {
        if (container.resolution_stack[i] == token)
        {
            return true;
        }
    }
    return false;
}

// Internal resolve with circular dependency detection
fn void* resolve_internal(DIContainer* container, String token)
{
    // Check for circular dependency
    if (has_circular_dependency(container, token))
    {
        io::printf("ERROR: Circular dependency detected for token: %s\n", token);
        return null;
    }
    
    // Add to resolution stack
    if (container.stack_depth < 128)
    {
        container.resolution_stack[container.stack_depth] = token;
        container.stack_depth++;
    }
    
    void* result = null;
    
    for (sz i = 0; i < container.provider_count; i++)
    {
        if (container.providers[i].token == token)
        {
            Provider* provider = &container.providers[i];
            
            if (provider.type == ProviderType.VALUE)
            {
                result = provider.instance;
            }
            else if (provider.type == ProviderType.EXISTING)
            {
                result = resolve_internal(container, (String)provider.provider);
            }
            else if (provider.scope == Scope.SINGLETON)
            {
                if (provider.instance == null)
                {
                    provider.instance = provider.provider;
                }
                result = provider.instance;
            }
            else if (provider.scope == Scope.TRANSIENT)
            {
                result = provider.provider;
            }
            else if (provider.scope == Scope.REQUEST)
            {
                // Request-scoped instances would be managed by request context
                // For now, treat as transient
                result = provider.provider;
            }
            
            break;
        }
    }
    
    // Remove from resolution stack
    if (container.stack_depth > 0)
    {
        container.stack_depth--;
    }
    
    return result;
}

// Public resolve function
fn void* resolve(DIContainer* container, String token)
{
    container.stack_depth = 0;
    return resolve_internal(container, token);
}

// Get provider count
fn sz get_provider_count(DIContainer* container)
{
    return container.provider_count;
}

// Check if provider exists
fn bool has_provider(DIContainer* container, String token)
{
    for (sz i = 0; i < container.provider_count; i++)
    {
        if (container.providers[i].token == token)
        {
            return true;
        }
    }
    return false;
}

