#include <glib-object.h>

GObjectClass* gobj_get_class(GObject* obj) { return G_OBJECT_GET_CLASS(obj); }

GType gobj_type(GObject* obj) { return G_OBJECT_TYPE(obj); }

const gchar* gobj_type_name(GObject* obj) { return G_OBJECT_TYPE_NAME(obj); }

GType gobj_class_type(GObjectClass* clazz) { return G_OBJECT_CLASS_TYPE(clazz); }

const gchar* gobj_class_name(GObjectClass* clazz) { return G_OBJECT_CLASS_NAME(clazz); }


