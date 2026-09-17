#include "register_types.h"
#include "core/config/engine.h"
#include "core/object/object.h"
#define CAIRN_BUILTIN
#include "../../aspect.c"

static Object *aspect_marker = nullptr;

void initialize_cairn_aspect_module(ModuleInitializationLevel level) {
    if (level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    aspect_marker = memnew(Object);
    Engine::get_singleton()->add_singleton(Engine::Singleton("CairnNativeAspect", aspect_marker));
    start_aspect();
}

void uninitialize_cairn_aspect_module(ModuleInitializationLevel level) {
    if (level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    stop_aspect();
    Engine::get_singleton()->remove_singleton("CairnNativeAspect");
    memdelete(aspect_marker);
    aspect_marker = nullptr;
}
