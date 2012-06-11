/* -*- Mode: C; indent-tabs-mode: nil; c-file-style: "bsd"; tab-width: 2; c-basic-offset: 2 -*- */
/*
 * gmobj.c
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

#include "gm-obj.h"

struct _GmObjPrivate
{
  gint number;
  const gchar* string;
  GmOther* other;
  GList* others;
};

enum
{
  PROP_0,

  PROP_NUMBER,
  PROP_STRING,
  PROP_OTHER,

  N_PROPERTIES
};

static GParamSpec* properties[N_PROPERTIES];

enum
{
  SIG_O_FULL,
  SIG_O_NONE,
  SIG_L_FULL,
  SIG_L_CONTAINER,
  SIG_L_NONE,
  SIG_S_RET_FULL,
  SIG_S_RET_NONE,

  N_SIGNALS
};

static guint signals[N_SIGNALS];

G_DEFINE_TYPE (GmObj, gm_obj, G_TYPE_OBJECT)

static void
gm_obj_default_o_full (GmObj* obj G_GNUC_UNUSED,
                       GmOther* other,
                       gpointer user_data G_GNUC_UNUSED)
{
  g_object_unref (other);
}

static void
gm_obj_default_o_none (GmObj* obj G_GNUC_UNUSED,
                       GmOther* other G_GNUC_UNUSED,
                       gpointer user_data G_GNUC_UNUSED)
{}

static void
gm_obj_default_l_full (GmObj* obj G_GNUC_UNUSED,
                       GList* others,
                       gpointer user_data G_GNUC_UNUSED)
{
  g_list_free_full (others, g_object_unref);
}

static void
gm_obj_default_l_container (GmObj* obj G_GNUC_UNUSED,
                            GList* others,
                            gpointer user_data G_GNUC_UNUSED)
{
  g_list_free (others);
}

static void
gm_obj_default_l_none (GmObj* obj G_GNUC_UNUSED,
                       GList* others G_GNUC_UNUSED,
                       gpointer user_data G_GNUC_UNUSED)
{}

static gchar*
gm_obj_default_s_ret_full (GmObj* obj, gpointer user_data)
{
  return g_strdup (obj->priv->string);
}

static const gchar*
gm_obj_default_s_ret_none (GmObj* obj, gpointer user_data)
{
  return obj->priv->string;
}

static void
gm_obj_set_property (GObject*       object,
                     guint          prop_id,
                     const GValue*  value,
                     GParamSpec*    pspec)
{
  GmObj* obj = GM_OBJ (object);

  switch (prop_id)
  {
  case PROP_NUMBER:
    gm_obj_set_number (obj, g_value_get_int (value));
    break;
  case PROP_STRING:
    gm_obj_set_string_t_n (obj, g_value_get_string (value));
    break;
  case PROP_OTHER:
    gm_obj_set_other_t_n (obj, g_value_get_object (value));
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
  }
}

static void
gm_obj_get_property (GObject* object,
                     guint prop_id,
                     GValue* value,
                     GParamSpec* pspec)
{
  GmObj* obj = GM_OBJ (object);

  switch (prop_id)
  {
  case PROP_NUMBER:
    g_value_set_int (value, gm_obj_get_number (obj));
    break;
  case PROP_STRING:
    g_value_set_string (value, gm_obj_get_string_t_n (obj));
    break;
  case PROP_OTHER:
    g_value_set_object (value, gm_obj_get_other_t_n (obj));
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
  }
}

static void
gm_obj_dispose (GObject *gobject)
{
  GmObj *obj = GM_OBJ (gobject);
  GmObjPrivate* priv = obj->priv;

  g_clear_object (&priv->other);

  if (priv->others)
  {
    GList* tmp = priv->others;

    priv->others = NULL;
    g_list_free_full (tmp, g_object_unref);
  }

  /* Chain up to the parent class */
  G_OBJECT_CLASS (gm_obj_parent_class)->dispose (gobject);
}

static void
gm_obj_finalize (GObject *gobject)
{
  GmObj *obj = GM_OBJ (gobject);
  GmObjPrivate* priv = obj->priv;

  g_free ((gpointer)priv->string);

  /* Chain up to the parent class */
  G_OBJECT_CLASS (gm_obj_parent_class)->finalize (gobject);
}

static void
gm_obj_class_init (GmObjClass* obj_class)
{
  GObjectClass* object_class = G_OBJECT_CLASS (obj_class);

  object_class->set_property = gm_obj_set_property;
  object_class->get_property = gm_obj_get_property;
  object_class->dispose = gm_obj_dispose;
  object_class->finalize = gm_obj_finalize;

  obj_class->o_full = gm_obj_default_o_full;
  obj_class->o_none = gm_obj_default_o_none;
  obj_class->l_full = gm_obj_default_l_full;
  obj_class->l_container = gm_obj_default_l_container;
  obj_class->l_none = gm_obj_default_l_none;
  obj_class->s_ret_full = gm_obj_default_s_ret_full;
  obj_class->s_ret_none = gm_obj_default_s_ret_none;

  properties[PROP_0] = NULL;
  /**
   * GmObj:number:
   *
   * A number property.
   */
  properties[PROP_NUMBER] = g_param_spec_int ("number",
                                              "Number",
                                              "Some number",
                                              G_MININT,
                                              G_MAXINT,
                                              42,
                                              G_PARAM_READWRITE | G_PARAM_CONSTRUCT);
  /**
   * GmObj:string:
   *
   * A string property.
   */
  properties[PROP_STRING] = g_param_spec_string ("string",
                                                 "String",
                                                 "Some string",
                                                 "GmObj",
                                                 G_PARAM_READWRITE | G_PARAM_CONSTRUCT);
  /**
   * GmObj:other:
   *
   * A #GmOther property.
   */
  properties[PROP_OTHER] = g_param_spec_object ("other",
                                                "Other",
                                                "Some other",
                                                GM_TYPE_OTHER,
                                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT);
  g_object_class_install_properties (object_class,
                                     N_PROPERTIES,
                                     properties);

  /**
   * GmObj::o-full:
   * @obj: A #GmObj.
   * @other: (transfer full): a #GmOther.
   *
   * @other has to be unreffed after use.
   */
  signals[SIG_O_FULL] =
    g_signal_new (g_intern_static_string("o-full"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  G_STRUCT_OFFSET (GmObjClass, o_full),
                  NULL, NULL,
                  NULL,
                  G_TYPE_NONE,
                  1, GM_TYPE_OTHER);

  /**
   * GmObj::o-none:
   * @obj: A #GmObj.
   * @other: (transfer none): a #GmOther.
   *
   * @other must not be unreffed after use.
   */
  signals[SIG_O_NONE] =
    g_signal_new (g_intern_static_string("o-none"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  G_STRUCT_OFFSET (GmObjClass, o_none),
                  NULL, NULL,
                  NULL,
                  G_TYPE_NONE,
                  1, GM_TYPE_OTHER);

  /**
   * GmObj::l-full:
   * @obj: A #GmObj.
   * @others: (transfer full) (type GList) (element-type GmOther): a #GList of #GmOther<!-- -->s.
   *
   * @others has to be freed with g_list_free_full() with g_object_unref() passed as #GDestroyNotify.
   */
  signals[SIG_L_FULL] =
    g_signal_new (g_intern_static_string("l-full"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  G_STRUCT_OFFSET (GmObjClass, l_full),
                  NULL, NULL,
                  NULL,
                  G_TYPE_NONE,
                  1, G_TYPE_POINTER);

  /**
   * GmObj::l-container:
   * @obj: A #GmObj.
   * @others: (transfer container) (type GList) (element-type GmOther): a #GList of #GmOther<!-- -->s.
   *
   * @others has to be freed with g_list_free(). Elements of the list are owned by @obj and should not be unreffed.
   */
  signals[SIG_L_CONTAINER] =
    g_signal_new (g_intern_static_string("l-container"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  G_STRUCT_OFFSET (GmObjClass, l_container),
                  NULL, NULL,
                  NULL,
                  G_TYPE_NONE,
                  1, G_TYPE_POINTER);

  /**
   * GmObj::l-none:
   * @obj: A #GmObj.
   * @others: (transfer none) (type GList) (element-type GmOther): a #GList of #GmOther<!-- -->s.
   *
   * @others and its elements are owned by @obj and should not be freed.
   */
  signals[SIG_L_NONE] =
    g_signal_new (g_intern_static_string("l-none"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_FIRST,
                  G_STRUCT_OFFSET (GmObjClass, l_none),
                  NULL, NULL,
                  NULL,
                  G_TYPE_NONE,
                  1, G_TYPE_POINTER);

  /**
   * GmObj::s-ret-full:
   * @obj: A #GmObj.
   *
   * Returns a string.
   *
   * Returns: (transfer full): A string that should be freed with g_free() after use.
   */
  signals[SIG_S_RET_FULL] =
    g_signal_new (g_intern_static_string("s-ret-full"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (GmObjClass, s_ret_full),
                  NULL, NULL,
                  NULL,
                  G_TYPE_STRING,
                  0);

  /**
   * GmObj::s-ret-none:
   * @obj: A #GmObj.
   *
   * Returns a string.
   *
   * Returns: (transfer none): A string that is taken over by @obj.
   */
  signals[SIG_S_RET_NONE] =
    g_signal_new (g_intern_static_string("s-ret-none"),
                  G_OBJECT_CLASS_TYPE (object_class),
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (GmObjClass, s_ret_none),
                  NULL, NULL,
                  NULL,
                  G_TYPE_STRING,
                  0);

  g_type_class_add_private (object_class, sizeof (GmObjPrivate));
}

static void
gm_obj_init (GmObj* obj)
{
  GmObjPrivate* priv = G_TYPE_INSTANCE_GET_PRIVATE(obj, GM_TYPE_OBJ, GmObjPrivate);

  if (!priv->other)
  {
    priv->other = gm_other_new ();
  }
  priv->others = NULL;

  obj->priv = priv;
}

/**
 * gm_obj_new:
 *
 * Creates new #GmObj.
 *
 * Returns: (transfer full): A new #GmObj.
 */
GmObj*
gm_obj_new (void)
{
  return GM_OBJ (g_object_new (GM_TYPE_OBJ, NULL));
}

/**
 * gm_obj_new_valid_names:
 *
 * @number: Number property.
 * @string: (transfer none): String property.
 * @other: Other property.
 *
 * Creates new #GmObj with some properties set.
 *
 * Returns: (transfer full): A new #GmObj.
 */
GmObj*
gm_obj_new_valid_names (gint number, gchar* string, GmOther* other)
{
  return GM_OBJ (g_object_new (GM_TYPE_OBJ,
                               "number", number,
                               "string", string,
                               "other", other,
                               NULL));
}

/**
 * gm_obj_new_bogus_names:
 *
 * @prop1: Other property.
 * @prop2: (transfer none): String property.
 * @prop3: Number property.
 *
 * Creates new #GmObj with some properties set.
 *
 * Returns: (transfer full): A new #GmObj.
 */
GmObj*
gm_obj_new_bogus_names (GmOther* prop1, gchar* prop2, gint prop3)
{
  return GM_OBJ (g_object_new (GM_TYPE_OBJ,
                               "number", prop3,
                               "string", prop2,
                               "other", prop1,
                               NULL));
}

/**
 * gm_obj_set_number:
 *
 * @obj: A #GmObj.
 * @number: A new number.
 *
 * Sets a number if current number is different from @number.
 * Emits a notification if setting is done.
 */
void
gm_obj_set_number (GmObj* obj, gint number)
{
  GmObjPrivate* priv;

  g_return_if_fail (GM_IS_OBJ (obj));

  priv = obj->priv;

  if (priv->number != number)
  {
    obj->priv->number = number;
    g_object_notify_by_pspec (G_OBJECT (obj), properties[PROP_NUMBER]);
  }
}

/**
 * gm_obj_get_number:
 *
 * @obj: A #GmObj.
 *
 * Gets a number.
 *
 * Returns: A number.
 */
gint
gm_obj_get_number (GmObj* obj)
{
  g_return_val_if_fail (GM_IS_OBJ (obj), 0);

  return obj->priv->number;
}

/**
 * gm_obj_set_string_t_n:
 *
 * @obj: A #GmObj.
 * @string: (transfer none): A new string.
 *
 * Sets a string if current string is different from @string.
 * Emits a notification if setting is done.
 */
void
gm_obj_set_string_t_n (GmObj* obj, const gchar* string)
{
  GmObjPrivate* priv;

  g_return_if_fail (GM_IS_OBJ (obj));
  g_return_if_fail (string != NULL);

  priv = obj->priv;

  if (g_strcmp0 (priv->string, string))
  {
    g_free ((gpointer)priv->string);
    priv->string = g_strdup (string);
    g_object_notify_by_pspec (G_OBJECT (obj), properties[PROP_STRING]);
  }
}

/**
 * gm_obj_set_string_t_f:
 *
 * @obj: A #GmObj.
 * @string: (transfer full): A new string.
 *
 * Sets a string if current string is different from @string.
 * Emits a notification if setting is done.
 */
void
gm_obj_set_string_t_f (GmObj* obj, const gchar* string)
{
  GmObjPrivate* priv;

  g_return_if_fail (GM_IS_OBJ (obj));
  g_return_if_fail (string != NULL);

  priv = obj->priv;

  if (g_strcmp0 (priv->string, string))
  {
    g_free ((gpointer)priv->string);
    priv->string = string;
    g_object_notify_by_pspec (G_OBJECT (obj), properties[PROP_STRING]);
  }
}

/**
 * gm_obj_get_string_t_f:
 *
 * @obj: A #GmObj.
 *
 * Gets a string.
 *
 * Returns: (transfer full): A string. Should be freed with g_free() when it is not needed.
 */
gchar*
gm_obj_get_string_t_f (GmObj* obj)
{
  g_return_val_if_fail (GM_IS_OBJ (obj), NULL);

  return g_strdup (obj->priv->string);
}

/**
 * gm_obj_get_string_t_n:
 *
 * @obj: A #GmObj.
 *
 * Gets a string.
 *
 * Returns: (transfer none): A string owned by @obj. Should be neither modifed nor freed.
 */
const gchar*
gm_obj_get_string_t_n (GmObj* obj)
{
  g_return_val_if_fail (GM_IS_OBJ (obj), NULL);

  return obj->priv->string;
}

/**
 * gm_obj_set_others_t_f:
 *
 * @obj: A #GmObj.
 * @others: (element-type GmOther) (transfer full): A new #GList with #GmOther
 * instances.
 *
 * Takes a list.
 */
void
gm_obj_set_others_t_f (GmObj* obj, GList* others)
{
  GmObjPrivate* priv;
  GList* tmp;

  g_return_if_fail (GM_IS_OBJ (obj));

  priv = obj->priv;
  tmp = priv->others;
  priv->others = others;
  g_list_free_full (tmp, g_object_unref);
}

/**
 * gm_obj_set_others_t_n:
 *
 * @obj: A #GmObj.
 * @others: (element-type GmOther) (transfer none): A #GList with #GmOther
 * instances.
 *
 * Copies given @others.
 */
void
gm_obj_set_others_t_n (GmObj* obj, GList* others)
{
  GmObjPrivate* priv;
  GList* tmp;
  GList* iter;
  GList* tmp2;

  g_return_if_fail (GM_IS_OBJ (obj));

  priv = obj->priv;
  tmp = priv->others;
  tmp2 = NULL;
  for (iter = others; iter; iter = g_list_next (iter))
  {
    tmp2 = g_list_prepend (tmp2, g_object_ref (iter->data));
  }
  priv->others = g_list_reverse (tmp2);
  g_list_free_full (tmp, g_object_unref);
}

/**
 * gm_obj_get_others_t_f:
 *
 * @obj: A #GmObj.
 *
 * Gets a list.
 *
 * Returns: (transfer full) (element-type GmOther): A list. Should be freed with
 * g_list_free_full() with g_object_unref() passed as a #GDestroyNotify.
 */
GList*
gm_obj_get_others_t_f (GmObj* obj)
{
  GmObjPrivate* priv;
  GList* new_list;
  GList* iter;

  g_return_val_if_fail (GM_IS_OBJ(obj), NULL);

  priv = obj->priv;
  new_list = NULL;

  for (iter = priv->others; iter; iter = g_list_next (iter))
  {
    new_list = g_list_prepend (new_list, g_object_ref (iter->data));
  }

  return g_list_reverse (new_list);
}

/**
 * gm_obj_get_others_t_c:
 *
 * @obj: A #GmObj.
 *
 * Gets a list
 *
 * Returns: (transfer container) (element-type GmOther): A list with elements
 * owned by @obj. Should be freed with g_list_free().
 */
GList*
gm_obj_get_others_t_c (GmObj* obj)
{
  GmObjPrivate* priv;
  GList* new_list;
  GList* iter;

  g_return_val_if_fail (GM_IS_OBJ(obj), NULL);

  priv = obj->priv;
  new_list = NULL;

  for (iter = priv->others; iter; iter = g_list_next (iter))
  {
    new_list = g_list_prepend (new_list, iter->data);
  }

  return g_list_reverse (new_list);
}

/**
 * gm_obj_get_others_t_n:
 *
 * @obj: A #GmObj.
 *
 * Gets a list
 *
 * Returns: (transfer none) (element-type GmOther): A list owned by @obj. Should
 * be neither modified nor freed.
 */
GList*
gm_obj_get_others_t_n (GmObj* obj)
{
  g_return_val_if_fail (GM_IS_OBJ(obj), NULL);

  return obj->priv->others;
}

/**
 * gm_obj_set_other_t_f:
 *
 * @obj: A #GmObj.
 * @other: A new #GmOther.
 *
 * Takes given @other if it is different from the current one.
 * Emits a notification if setting is done.
 */
void
gm_obj_set_other_t_f (GmObj* obj,
                      GmOther* other)
{
  GmObjPrivate* priv;

  g_return_if_fail (GM_IS_OBJ (obj));
  g_return_if_fail (GM_IS_OTHER (other));

  priv = obj->priv;
  if (other != priv->other)
  {
    GmOther* tmp = priv->other;

    priv->other = other;
    if (tmp)
    {
      g_object_unref (tmp);
    }
    g_object_notify_by_pspec (G_OBJECT (obj), properties[PROP_OTHER]);
  }
}

/**
 * gm_obj_set_other_t_n:
 *
 * @obj: A #GmObj.
 * @other: A new #GmOther.
 *
 * Sets a #GmOther if current one is different from @other.
 * Emits a notification if setting is done.
 */
void
gm_obj_set_other_t_n (GmObj* obj,
                      GmOther* other)
{
  GmObjPrivate* priv;

  g_return_if_fail (GM_IS_OBJ (obj));
  g_return_if_fail (GM_IS_OTHER (other));

  priv = obj->priv;
  if (other != priv->other)
  {
    GmOther* tmp = priv->other;

    priv->other = g_object_ref (other);
    if (tmp)
    {
      g_object_unref (tmp);
    }
    g_object_notify_by_pspec (G_OBJECT (obj), properties[PROP_OTHER]);
  }
}

/**
 * gm_obj_get_other_t_f:
 *
 * @obj: A #GmObj.
 *
 * Gets an other.
 *
 * Returns: (transfer full): A #GmOther. Should be freed with g_object_unref()
 * when it is not needed.
 */
GmOther*
gm_obj_get_other_t_f (GmObj* obj)
{
  GmObjPrivate* priv;

  g_return_val_if_fail (GM_IS_OBJ (obj), NULL);

  priv = obj->priv;

  if (priv->other)
  {
    return g_object_ref (priv->other);
  }
  return NULL;
}

/**
 * gm_obj_get_other_t_n:
 *
 * @obj: A #GmObj.
 *
 * Gets an other.
 *
 * Returns: (transfer none): A #GmOther owned by @obj. Should be neither
 * modified nor freed.
 */
GmOther*
gm_obj_get_other_t_n (GmObj* obj)
{
  g_return_val_if_fail (GM_IS_OBJ (obj), NULL);

  return obj->priv->other;
}

/**
 * gm_obj_set_string_allow_none:
 * @obj: A #GmObj.
 * @str: (transfer none) (allow-none): A string or %NULL.
 *
 * Does nothing actually.
 */
void
gm_obj_set_string_allow_none (GmObj* obj,
                              const gchar* str)
{
  g_return_if_fail (GM_IS_OBJ (obj));
}
