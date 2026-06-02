module middleware::compose;
import router::layer;
import core::context;

Layer[] global_stack;
int global_index;

fn void next_wrapper(Context* ctx)
{
    dispatch(ctx, global_stack, global_index + 1);
}

fn void dispatch(Context* ctx, Layer[] stack, int index)
{
    if (index >= (int)stack.len) return;

    global_stack = stack;
    global_index = index;

    Layer* layer = &stack[index];

    if (layer.type == LayerType.MIDDLEWARE)
    {
        layer.middleware(ctx, &next_wrapper);
    }
}
