/* generate_extra_defs.cc
 *
 * Copyright (C) 2001 The Free Software Foundation
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

#include "generate_extra_defs.h"
#include <algorithm>

std::string
get_property_with_node_name(
  GParamSpec* pParamSpec, const std::string& strObjectName, const std::string& strNodeName)
{
  std::string strResult;

  // Name and type:
  const std::string strName = g_param_spec_get_name(pParamSpec);
  const std::string strTypeName = G_PARAM_SPEC_TYPE_NAME(pParamSpec);

  const gchar* pchBlurb = g_param_spec_get_blurb(pParamSpec);
  std::string strDocs = (pchBlurb) ? pchBlurb : "";
  // Quick hack to get rid of nested double quotes:
  std::replace(strDocs.begin(), strDocs.end(), '"', '\'');

  strResult += "(" + strNodeName + " " + strName + "\n";
  strResult += "  (of-object \"" + strObjectName + "\")\n";
  strResult += "  (prop-type \"" + strTypeName + "\")\n";
  strResult += "  (docs \"" + strDocs + "\")\n";

  // Flags:
  GParamFlags flags = pParamSpec->flags;
  bool bReadable = (flags & G_PARAM_READABLE) == G_PARAM_READABLE;
  bool bWritable = (flags & G_PARAM_WRITABLE) == G_PARAM_WRITABLE;
  bool bConstructOnly = (flags & G_PARAM_CONSTRUCT_ONLY) == G_PARAM_CONSTRUCT_ONLY;
  bool bDeprecated = (flags & G_PARAM_DEPRECATED) == G_PARAM_DEPRECATED;

  //#t and #f aren't documented, but I guess that it's correct based on the example in the .defs
  // spec.
  const std::string strTrue = "#t";
  const std::string strFalse = "#f";

  strResult += "  (readable " + (bReadable ? strTrue : strFalse) + ")\n";
  strResult += "  (writable " + (bWritable ? strTrue : strFalse) + ")\n";
  strResult += "  (construct-only " + (bConstructOnly ? strTrue : strFalse) + ")\n";
  if (bDeprecated)
    strResult += "  (deprecated #t)\n"; // Default: not deprecated

  strResult += ")\n\n"; // close (strNodeName

  return strResult;
}

// Until the glib bug https://bugzilla.gnome.org/show_bug.cgi?id=465631
// is fixed, get_properties() must be called for a GObject before it's
// called for a GInterface.
std::string
get_properties(GType gtype)
{
  std::string strResult;
  std::string strObjectName = g_type_name(gtype);

  // Get the list of properties:
  GParamSpec** ppParamSpec = nullptr;
  guint iCount = 0;
  if (G_TYPE_IS_OBJECT(gtype))
  {
    GObjectClass* pGClass = G_OBJECT_CLASS(g_type_class_ref(gtype));
    ppParamSpec = g_object_class_list_properties(pGClass, &iCount);
    g_type_class_unref(pGClass);

    if (!ppParamSpec)
    {
      strResult += ";; Warning: g_object_class_list_properties() returned NULL for " +
                   std::string(g_type_name(gtype)) + "\n";
    }
  }
  else if (G_TYPE_IS_INTERFACE(gtype))
  {
    gpointer pGInterface = g_type_default_interface_ref(gtype);
    if (pGInterface)
    {
      ppParamSpec = g_object_interface_list_properties(pGInterface, &iCount);
      g_type_default_interface_unref(pGInterface);

      if (!ppParamSpec)
      {
        strResult += ";; Warning: g_object_interface_list_properties() returned NULL for " +
                     std::string(g_type_name(gtype)) + "\n";
      }
    }
    else
      strResult += ";; Warning: g_type_default_interface_ref() returned NULL for " +
                   std::string(g_type_name(gtype)) + "\n";
  }

  // This extra check avoids an occasional crash
  if (!ppParamSpec)
    iCount = 0;

  for (guint i = 0; i < iCount; i++)
  {
    GParamSpec* pParamSpec = ppParamSpec[i];
    // Generate the property if the specified gtype actually owns the property.
    // (Generally all properties, including any base classes' properties are
    // retrieved by g_object_interface_list_properties() for a given gtype.
    // The base classes' properties should not be generated).
    if (pParamSpec && pParamSpec->owner_type == gtype)
    {
      strResult += get_property_with_node_name(pParamSpec, strObjectName, "define-property");
    }
  }

  g_free(ppParamSpec);

  return strResult;
}

bool
gtype_is_a_pointer(GType gtype)
{
  return (g_type_is_a(gtype, G_TYPE_OBJECT) || g_type_is_a(gtype, G_TYPE_BOXED));
}

std::string get_type_name(
  GType gtype, GTypeIsAPointerFunc is_a_pointer_func) // Adds a * if necessary.
{
  std::string strTypeName = g_type_name(gtype);

  if (is_a_pointer_func && is_a_pointer_func(gtype))
    strTypeName += "*"; // Add * to show that it's a pointer.
  else if (g_type_is_a(gtype, G_TYPE_STRING))
    strTypeName = "gchar*"; // g_type_name() returns "gchararray".

  return strTypeName;
}

std::string
get_type_name_parameter(GType gtype, GTypeIsAPointerFunc is_a_pointer_func)
{
  std::string strTypeName = get_type_name(gtype, is_a_pointer_func);

  // All signal parameters that are registered as GTK_TYPE_STRING are actually const gchar*.
  if (strTypeName == "gchar*")
    strTypeName = "const-gchar*";

  return strTypeName;
}

std::string
get_type_name_signal(GType gtype, GTypeIsAPointerFunc is_a_pointer_func)
{
  return get_type_name_parameter(
    gtype, is_a_pointer_func); // At the moment, it needs the same stuff.
}

std::string
get_signals(GType gtype, GTypeIsAPointerFunc is_a_pointer_func)
{
  std::string strResult;
  std::string strObjectName = g_type_name(gtype);

  gpointer gclass_ref = nullptr;
  gpointer ginterface_ref = nullptr;

  if (G_TYPE_IS_OBJECT(gtype))
    gclass_ref = g_type_class_ref(gtype); // Ensures that class_init() is called.
  else if (G_TYPE_IS_INTERFACE(gtype))
    ginterface_ref = g_type_default_interface_ref(gtype); // install signals.

  // Get the list of signals:
  guint iCount = 0;
  guint* pIDs = g_signal_list_ids(gtype, &iCount);

  // Loop through the list of signals:
  if (pIDs)
  {
    for (guint i = 0; i < iCount; i++)
    {
      guint signal_id = pIDs[i];

      // Name:
      std::string strName = g_signal_name(signal_id);
      strResult += "(define-signal " + strName + "\n";
      strResult += "  (of-object \"" + strObjectName + "\")\n";

      // Other information about the signal:
      GSignalQuery signalQuery = {
        0, nullptr, 0, GSignalFlags(0), 0, 0, nullptr,
      };
      g_signal_query(signal_id, &signalQuery);

      // Return type:
      std::string strReturnTypeName =
        get_type_name_signal(signalQuery.return_type & ~G_SIGNAL_TYPE_STATIC_SCOPE,
          is_a_pointer_func); // The type is mangled with a flag. Hacky.
      // bool bReturnTypeHasStaticScope = (signalQuery.return_type & G_SIGNAL_TYPE_STATIC_SCOPE) ==
      // G_SIGNAL_TYPE_STATIC_SCOPE;
      strResult += "  (return-type \"" + strReturnTypeName + "\")\n";

      // When:
      {
        bool bWhenFirst = (signalQuery.signal_flags & G_SIGNAL_RUN_FIRST) == G_SIGNAL_RUN_FIRST;
        bool bWhenLast = (signalQuery.signal_flags & G_SIGNAL_RUN_LAST) == G_SIGNAL_RUN_LAST;

        std::string strWhen = "unknown";

        if (bWhenFirst && bWhenLast)
          strWhen = "both";
        else if (bWhenFirst)
          strWhen = "first";
        else if (bWhenLast)
          strWhen = "last";

        strResult += "  (when \"" + strWhen + "\")\n";
      }
      bool bDeprecated = (signalQuery.signal_flags & G_SIGNAL_DEPRECATED) == G_SIGNAL_DEPRECATED;
      if (bDeprecated)
        strResult += "  (deprecated #t)\n"; // Default: not deprecated

      // Loop through the list of parameters:
      const GType* pParameters = signalQuery.param_types;
      if (pParameters)
      {
        strResult += "  (parameters\n";

        for (unsigned j = 0; j < signalQuery.n_params; j++)
        {
          GType typeParamMangled = pParameters[j];

          // Parameter name:
          // We can't get the real parameter name from the GObject system. It's not registered with
          // g_signal_new().
          gchar* pchNum = g_strdup_printf("%d", j);
          std::string strParamName = "p" + std::string(pchNum);
          g_free(pchNum);
          pchNum = nullptr;

          // Just like above, for the return type:
          std::string strTypeName =
            get_type_name_signal(typeParamMangled & ~G_SIGNAL_TYPE_STATIC_SCOPE,
              is_a_pointer_func); // The type is mangled with a flag. Hacky.
          // bool bTypeHasStaticScope = (typeParamMangled & G_SIGNAL_TYPE_STATIC_SCOPE) ==
          // G_SIGNAL_TYPE_STATIC_SCOPE;

          strResult += "    '(\"" + strTypeName + "\" \"" + strParamName + "\")\n";
        }

        strResult += "  )\n"; // close (parameters
      }

      strResult += ")\n\n"; // close (define-signal
    }
  }

  g_free(pIDs);

  if (gclass_ref)
    g_type_class_unref(gclass_ref); // to match the g_type_class_ref() above.
  else if (ginterface_ref)
    g_type_default_interface_unref(ginterface_ref); // for interface ref above.

  return strResult;
}

std::string
get_defs(GType gtype, GTypeIsAPointerFunc is_a_pointer_func)
{
  std::string strObjectName = g_type_name(gtype);
  std::string strDefs;

  if (G_TYPE_IS_OBJECT(gtype) || G_TYPE_IS_INTERFACE(gtype))
  {
    strDefs = ";; From " + strObjectName + "\n\n";
    strDefs += get_signals(gtype, is_a_pointer_func);
    strDefs += get_properties(gtype);
  }
  else
    strDefs = ";; " + strObjectName +
              " is neither a GObject nor a GInterface. Not checked for signals and properties.\n\n";

  return strDefs;
}
