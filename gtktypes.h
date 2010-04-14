/* Copyright 2010 Daniel Silva */
/* Distributed under the AGPL v3.  See LICENSE file. */

#include <glib-object.h>

GObjectClass* gobj_get_class(GObject* obj);

GType gobj_type(GObject* obj);

const gchar* gobj_type_name(GObject* obj);

GType gobj_class_type(GObjectClass* clazz);

const gchar* gobj_class_name(GObjectClass* clazz);



