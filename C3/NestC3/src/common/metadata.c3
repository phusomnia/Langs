module common::metadata;

const METADATA_KEY_CONTROLLER = "controller";
const METADATA_KEY_ROUTE = "route";
const METADATA_KEY_PARAM = "param";
const METADATA_KEY_INJECTABLE = "injectable";
const METADATA_KEY_MODULE = "module";

struct MetadataEntry
{
    String key;
    void* value;
}

struct TypeMetadata
{
    String type_id;
    MetadataEntry[64] entries;
    sz entry_count;
}

struct MetadataStorage
{
    TypeMetadata[128] types;
    sz type_count;
}

MetadataStorage global_metadata;

fn void init_metadata()
{
    global_metadata.type_count = 0;
}

// Internal helper: find or create type metadata
fn TypeMetadata* get_or_create_type_metadata(String type_id)
{
    for (sz i = 0; i < global_metadata.type_count; i++)
    {
        if (global_metadata.types[i].type_id == type_id)
        {
            return &global_metadata.types[i];
        }
    }
    
    if (global_metadata.type_count >= 128) return null;
    
    TypeMetadata* new_type = &global_metadata.types[global_metadata.type_count];
    new_type.type_id = type_id;
    new_type.entry_count = 0;
    global_metadata.type_count++;
    
    return new_type;
}

// Set metadata for a specific type
fn void set_metadata(String type_id, String key, void* data)
{
    TypeMetadata* type_meta = get_or_create_type_metadata(type_id);
    if (type_meta == null) return;
    
    // Check if key already exists
    for (sz i = 0; i < type_meta.entry_count; i++)
    {
        if (type_meta.entries[i].key == key)
        {
            type_meta.entries[i].value = data;
            return;
        }
    }
    
    // Add new entry
    if (type_meta.entry_count >= 64) return;
    type_meta.entries[type_meta.entry_count].key = key;
    type_meta.entries[type_meta.entry_count].value = data;
    type_meta.entry_count++;
}

// Get metadata for a specific type
fn void* get_metadata(String type_id, String key)
{
    for (sz i = 0; i < global_metadata.type_count; i++)
    {
        if (global_metadata.types[i].type_id == type_id)
        {
            TypeMetadata* type_meta = &global_metadata.types[i];
            for (sz j = 0; j < type_meta.entry_count; j++)
            {
                if (type_meta.entries[j].key == key)
                {
                    return type_meta.entries[j].value;
                }
            }
        }
    }
    return null;
}

// Check if metadata exists for a type
fn bool has_metadata(String type_id, String key)
{
    return get_metadata(type_id, key) != null;
}

// Get all types that have a specific metadata key
fn String[] get_types_with_metadata(String key, String[] out, sz* count)
{
    *count = 0;
    for (sz i = 0; i < global_metadata.type_count; i++)
    {
        TypeMetadata* type_meta = &global_metadata.types[i];
        for (sz j = 0; j < type_meta.entry_count; j++)
        {
            if (type_meta.entries[j].key == key)
            {
                if (*count < 128)
                {
                    out[*count] = type_meta.type_id;
                    (*count)++;
                }
                break;
            }
        }
    }
    return out;
}

// Backward compatibility: global metadata functions
fn void set_metadata_global(String key, void* data)
{
    set_metadata("__global__", key, data);
}

fn void* get_metadata_global(String key)
{
    return get_metadata("__global__", key);
}

fn bool has_metadata_global(String key)
{
    return has_metadata("__global__", key);
}
