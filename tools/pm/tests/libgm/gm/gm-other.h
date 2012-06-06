/* -*- Mode: C; indent-tabs-mode: nil; c-file-style: "bsd"; tab-width: 2; c-basic-offset: 2 -*- */
/*
 * gmother.h
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

#ifndef GLIBMM_TEST_GM_OTHER_H
#define GLIBMM_TEST_GM_OTHER_H

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define GM_TYPE_OTHER             (gm_other_get_type ())
#define GM_OTHER(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GM_TYPE_OTHER, GmOther))
#define GM_OTHER_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GM_TYPE_OTHER, GmOtherClass))
#define GM_IS_OTHER(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GM_TYPE_OTHER))
#define GM_IS_OTHER_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GM_TYPE_OTHER))
#define GM_OTHER_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GM_TYPE_OTHER, GmOtherClass))

typedef struct _GmOther         GmOther;
typedef struct _GmOtherClass    GmOtherClass;

struct _GmOther
{
  GObject parent;
};

struct _GmOtherClass
{
  GObjectClass parent_class;
};

GType
gm_other_get_type (void) G_GNUC_CONST;

GmOther*
gm_other_new (void);

G_END_DECLS

#endif /* GLIBMM_TEST_GM_OTHER_H */
