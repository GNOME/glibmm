/* -*- Mode: C; indent-tabs-mode: nil; c-file-style: "bsd"; tab-width: 2; c-basic-offset: 2 -*- */
/*
 * gmother.c
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

#include "gm-other.h"

G_DEFINE_TYPE (GmOther, gm_other, G_TYPE_OBJECT)

static void
gm_other_class_init (GmOtherClass* klass G_GNUC_UNUSED)
{}

static void
gm_other_init (GmOther* other G_GNUC_UNUSED)
{}

/**
 * gm_other_new:
 *
 * Creates new #GmOther.
 *
 * Returns: (transfer full): A new #GmOther.
 */
GmOther*
gm_other_new (void)
{
  return GM_OTHER (g_object_new (GM_TYPE_OTHER, NULL));
}
