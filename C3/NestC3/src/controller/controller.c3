module controller::controller;

import core::context;

struct Controller
{
    String path;
    void* instance;
}

fn Controller init_controller(String path, void* instance)
{
    Controller controller;
    controller.path = path;
    controller.instance = instance;
    return controller;
}
