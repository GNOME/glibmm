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
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "generate_extra_defs.h"
#include <algorithm>
#include <regex>
#include <sstream>

namespace
{
void add_signal_flag_if(std::string& strFlags, const char* strFlag,
  const GSignalQuery& signalQuery, GSignalFlags flag)
{
  if (signalQuery.signal_flags & flag)
  {
    if (!strFlags.empty())
      strFlags += ", ";
    strFlags += strFlag;
  }
}

} // anonymous namespace

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

  // Default value:
  const GValue* defValue = g_param_spec_get_default_value(pParamSpec);
  std::string defString;
  bool defValueExists = false;
  if (G_VALUE_HOLDS_STRING(defValue))
  {
    defValueExists = true;
    const char* defCString = g_value_get_string(defValue);
    if (defCString)
    {
      // Replace newlines with \n.
      // A string default value can contain newline characters.
      // gmmproc removes all newlines when it reads .defs files.
      defString = std::regex_replace(defCString, std::regex("\n"), "\\n");
    }
    else
      defString = ""; // A NULL string pointer becomes an empty string.
  }
  else if (G_VALUE_HOLDS_FLOAT(defValue) || G_VALUE_HOLDS_DOUBLE(defValue))
  {
    // g_value_transform() can transform a floating point value to a terrible
    // string, especially if the value is huge.
    defValueExists = true;
    const double defDouble = G_VALUE_HOLDS_FLOAT(defValue) ?
      g_value_get_float(defValue) : g_value_get_double(defValue);
    std::ostringstream defStringStream;
    defStringStream << defDouble;
    defString = defStringStream.str();
  }
  else
  {
    GValue defStringValue = G_VALUE_INIT;
    g_value_init(&defStringValue, G_TYPE_STRING);

    if (g_value_transform(defValue, &defStringValue))
    {
      const char* defCString = g_value_get_string(&defStringValue);
      if (defCString)
      {
        defValueExists = true;
        defString = defCString;
      }
    }
    g_value_unset(&defStringValue);
  }

  if (defValueExists)
    strResult += "  (default-value \"" + defString + "\")\n";

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

      // Flags:
      std::string strFlags;
      add_signal_flag_if(strFlags, "Run First", signalQuery, G_SIGNAL_RUN_FIRST);
      add_signal_flag_if(strFlags, "Run Last", signalQuery, G_SIGNAL_RUN_LAST);
      add_signal_flag_if(strFlags, "Run Cleanup", signalQuery, G_SIGNAL_RUN_CLEANUP);
      add_signal_flag_if(strFlags, "No Recurse", signalQuery, G_SIGNAL_NO_RECURSE);
      add_signal_flag_if(strFlags, "Action", signalQuery, G_SIGNAL_ACTION);
      add_signal_flag_if(strFlags, "No Hooks", signalQuery, G_SIGNAL_NO_HOOKS);
      add_signal_flag_if(strFlags, "Must Collect", signalQuery, G_SIGNAL_MUST_COLLECT);
      strResult += "  (flags \"" + strFlags + "\")\n";

      if (signalQuery.signal_flags & G_SIGNAL_DETAILED)
        strResult += "  (detailed #t)\n"; // Default: not detailed

      if (signalQuery.signal_flags & G_SIGNAL_DEPRECATED)
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
