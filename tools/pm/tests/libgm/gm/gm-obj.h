/* -*- Mode: C; indent-tabs-mode: nil; c-file-style: "bsd"; tab-width: 2; c-basic-offset: 2 -*- */
/*
 * gmobj.h
 * This file is part of glibmm
 *
 * Copyright 2012 - Krzesimir Nowak <qdlacz@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef GLIBMM_TEST_GM_OBJ_H
#define GLIBMM_TEST_GM_OBJ_H

#include <glib.h>
#include <glib-object.h>

#include "gm-other.h"

G_BEGIN_DECLS

#define GM_TYPE_OBJ             (gm_obj_get_type ())
#define GM_OBJ(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GM_TYPE_OBJ, GmObj))
#define GM_OBJ_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GM_TYPE_OBJ, GmObjClass))
#define GM_IS_OBJ(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GM_TYPE_OBJ))
#define GM_IS_OBJ_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GM_TYPE_OBJ))
#define GM_OBJ_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GM_TYPE_OBJ, GmObjClass))

typedef struct _GmObj         GmObj;
typedef struct _GmObjClass    GmObjClass;
typedef struct _GmObjPrivate  GmObjPrivate;

struct _GmObj
{
  GObject parent;

  /*< private >*/
  GmObjPrivate* priv;
};

struct _GmObjClass
{
  GObjectClass parent_class;

  /* signals */
  void (* o_full) (GmObj* obj, GmOther* other, gpointer user_data);
  void (* o_none) (GmObj* obj, GmOther* other, gpointer user_data);
  void (* l_full) (GmObj* obj, GList* others, gpointer user_data);
  void (* l_container) (GmObj* obj, GList* others, gpointer user_data);
  void (* l_none) (GmObj* obj, GList* others, gpointer user_data);
  gchar* (* s_ret_full) (GmObj* obj, gpointer user_data);
  const gchar* (* s_ret_none) (GmObj* obj, gpointer user_data);

  /* TODO: vfuncs */
};

GType
gm_obj_get_type (void) G_GNUC_CONST;

GmObj*
gm_obj_new (void);

GmObj*
gm_obj_new_valid_names (gint number,
                        gchar* string,
                        GmOther* other);

GmObj*
gm_obj_new_bogus_names (GmOther* prop1,
                        gchar* prop2,
                        gint prop3);

void
gm_obj_set_number (GmObj* obj,
                   gint number);

gint
gm_obj_get_number (GmObj* obj);

void
gm_obj_set_string_t_n (GmObj* obj,
                       const gchar* string);

void
gm_obj_set_string_t_f (GmObj* obj,
                       const gchar* string);

gchar*
gm_obj_get_string_t_f (GmObj* obj);

const gchar*
gm_obj_get_string_t_n (GmObj* obj);

/* This API is wrong I guess - transfers of container in parameters should be always none. Will not be wrapped in C++ bindings. */
void
gm_obj_set_others_t_f (GmObj* obj,
                       GList* others);

/* Makes no sense:
void
gm_obj_set_others_t_c (GmObj* obj,
                       GList* others);
*/

void
gm_obj_set_others_t_n (GmObj* obj,
                       GList* others);

GList*
gm_obj_get_others_t_f (GmObj* obj);

GList*
gm_obj_get_others_t_c (GmObj* obj);

GList*
gm_obj_get_others_t_n (GmObj* obj);

void
gm_obj_set_other_t_f (GmObj* obj,
                      GmOther* other);

void
gm_obj_set_other_t_n (GmObj* obj,
                      GmOther* other);

GmOther*
gm_obj_get_other_t_f (GmObj* obj);

GmOther*
gm_obj_get_other_t_n (GmObj* obj);

G_END_DECLS

#endif /* GLIBMM_TEST_GM_OBJ_H */
