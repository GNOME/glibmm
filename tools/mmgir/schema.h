/* Copyright (C) 2026 Daniel Gao <daniel.gao.work@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include <memory>
#include <optional>
#include <string>
#include <variant>
#include <vector>

// Schema based on gir-1.2.rnc
// https://gitlab.gnome.org/GNOME/gobject-introspection/-/blob/main/docs/gir-1.2.rnc
namespace gir {

struct ArrayType;
struct Namespace;
struct Type;

enum class Dir { IN, OUT, INOUT };
enum class RunSignal { FIRST, LAST, CLEANUP };
enum class Scope { NOTIFIED, ASYNC, CALL, FOREVER };
enum class Stability { STABLE, UNSTABLE, PRIVATE, UNKNOWN };
enum class TransferOwnership { NONE, CONTAINER, FULL };

struct Repository
{
    std::optional<std::string> version;
    // Prefixes to filter out from C identifiers for data structures and types
    std::vector<std::string> identifier_prefixes;
    // Prefixes to filter out from C functions
    std::vector<std::string> symbol_prefixes;

    std::vector<Namespace> namespaces;
};

struct Annotation
{
    std::string name;
    std::string value;
};

struct InfoAttributes
{
    bool is_skippable = false;  // introspectable == "0"
    std::optional<bool> is_deprecated;
    std::optional<std::string> deprecated_version;
    std::string version;
    Stability stability = Stability::UNKNOWN;
};

struct SourcePosition
{
    std::string filename;
    int line = 0;
    std::optional<int> column = 0;
};

struct Documentation
{
    SourcePosition src_pos;
    std::string text;
};

struct DocElements
{
    std::optional<Documentation> doc;
    std::optional<SourcePosition> src_pos;
};

struct InfoElements
{
    DocElements doc_elements;
    std::vector<Annotation> annotations;
};

using AnyType = std::variant<Type*, ArrayType*>;

struct Type
{
    // The name is the (possibly namespaced) GObject name of the type. I have
    // not observed cases where it is empty.
    //
    // Examples:
    //
    // <type name="utf8" c:type="gchar*"/>
    // <type name="gpointer" c:type="gpointer"/>
    // <type name="ActionEntry" c:type="GtkActionEntry"/>
    // <type name="Gdk.ModifierType" c:type="GdkModifierType"/>
    // <type name="GdkPixbuf.Pixbuf"/>
    std::optional<std::string> name;
    // May be empty (e.g. in properties) in which case the C type needs to be
    // resolved based on the GObject name from other types in the current or
    // different namespaces.
    std::optional<std::string> c_type;

    DocElements doc_elements;
    // If the type is a container type, the child type gives the type of the
    // container's elements.
    //
    // <type name="GLib.SList" c:type="GSList*">
    //   <type name="BindingArg"/>
    // </type>
    // std::vector<AnyType> sub_type;
};

// <array>
//   <type name="utf8"/>
// </array>

struct ArrayType
{
    std::optional<std::string> name;
    // If provided, the value is the full C type of the array.
    //
    // Examples:
    //
    //   <array c:type="const gchar**">
    //     <type name="utf8" c:type="gchar*"/>
    //   </array>
    //   <array c:type="const gchar* const*">
    //     <type name="utf8"/>
    //   </array>
    //
    // If not provided, the C type may be available from another location. In
    // properties, the getter/setter functions should provide the type.
    //
    // Example:
    //
    //   <property name="documenters"
    //             setter="set_documenters"
    //             getter="get_documenters">
    //     <array>
    //       <type name="utf8"/>
    //     </array>
    //   </property>
    //   <method name="get_documenters"
    //           c:identifier="gtk_about_dialog_get_documenters"
    //           glib:get-property="documenters">
    //     <return-value transfer-ownership="none">
    //       <array c:type="const gchar* const*">
    //         <type name="utf8"/>
    //       </array>
    //     </return-value>
    //   </method>
    //   <method name="set_documenters"
    //                 c:identifier="gtk_about_dialog_set_documenters"
    //                 glib:set-property="documenters">
    //     <parameters>
    //       <parameter name="documenters" transfer-ownership="none">
    //         <array c:type="const gchar**">
    //           <type name="utf8" c:type="gchar*"/>
    //         </array>
    //       </parameter>
    //     </parameters>
    //   </method>
    std::optional<std::string> c_type;
    std::optional<bool> is_zero_terminated;
    std::optional<int> length;
    std::optional<int> fixed_size;

    AnyType element_type = static_cast<Type*>(nullptr);
};

struct VarArgs {};

struct Alias
{
    InfoAttributes info_attributes;
    std::string name;
    std::string c_type;

    InfoElements info_elements;
    std::optional<AnyType> type;
};

struct Member
{
    InfoAttributes info_attributes;
    std::string name;
    std::string value;
    std::string c_identifier;
    std::optional<std::string> nickname;

    InfoElements info_elements;
};

struct CallableAttributes
{
    InfoAttributes info_attributes;
    std::string name;
    std::optional<std::string> c_identifier;
    std::optional<std::string> shadowed_by;
    std::optional<std::string> shadows;
    std::optional<std::string> moved_to;
    std::optional<std::string> async_func;
    std::optional<std::string> sync_func;
    std::optional<std::string> finish_func;
    std::optional<bool> can_throw;
};

struct Param
{
    std::optional<std::string> name;
    std::optional<bool> is_nullable;
    std::optional<int> closure;
    std::optional<int> destroy;
    std::optional<Scope> scope;
    std::optional<Dir> direction;
    std::optional<bool> is_caller_allocated;
    std::optional<bool> is_optional;
    std::optional<bool> is_skippable;
    std::optional<TransferOwnership> ownership;

    InfoElements info_elements;
    std::optional<std::variant<VarArgs, AnyType>> type;
};

struct InstanceParam
{
    std::string name;
    std::optional<bool> is_nullable;
    std::optional<Dir> direction;
    std::optional<bool> is_caller_allocated;
    std::optional<TransferOwnership> ownership;

    DocElements doc_elements;
    Type* type;
};

struct CallableParams
{
    std::vector<Param> params;
    std::optional<InstanceParam> instance_param;
};

struct CallableReturn
{
    std::optional<bool> is_nullable;
    std::optional<int> closure;
    std::optional<int> destroy;
    std::optional<Scope> scope;
    std::optional<bool> is_skippable;
    std::optional<TransferOwnership> ownership;

    InfoElements info_elements;
    AnyType type = static_cast<Type*>(nullptr);
};

struct FunctionInline
{
    CallableAttributes attributes;

    // Must not have instance parameter when not wrapped by one of the method
    // schema structs (i.e. free function)
    std::optional<CallableParams> params;
    std::optional<CallableReturn> return_type;
    DocElements doc_elements;
};

struct Function
{
    // Must not have instance parameter when not wrapped by one of the method
    // schema structs (i.e. free function)
    FunctionInline detail;
    std::vector<Annotation> annotations;
};

struct MethodInline
{
    // Instance parameter is mandatory
    Function func;
};

struct Method
{
    // Instance parameter is mandatory
    Function func;

    std::optional<std::string> set_property;
    std::optional<std::string> get_property;
};

struct Constructor
{
    // Must not have instance parameter (free function)
    Function func;
};

struct VirtualMethod
{
    // Instance parameter is mandatory
    Function func;

    std::optional<std::string> invoker;
};

struct Bitfield
{
    InfoAttributes info_attributes;
    std::string name;
    std::string c_type;
    std::optional<std::string> glib_type_name;
    std::optional<std::string> glib_type_func;

    InfoElements info_elements;
    std::vector<Member> members;
    std::vector<Function> functions;
    std::vector<FunctionInline> inline_functions;
};

struct Enum
{
    InfoAttributes info_attributes;
    std::string name;
    std::string c_type;
    std::optional<std::string> glib_type_name;
    std::optional<std::string> glib_type_func;
    std::optional<std::string> error_domain;

    InfoElements info_elements;
    std::vector<Member> members;
    std::vector<Function> functions;
    std::vector<FunctionInline> inline_functions;
};

struct Property 
{
    InfoAttributes info_attributes;
    std::string name;
    std::optional<bool> is_writable;
    std::optional<bool> is_readable;
    std::optional<bool> is_set_on_construction;
    std::optional<bool> is_set_only_during_construction;
    std::optional<std::string> setter_func;
    std::optional<std::string> getter_func;
    std::optional<std::string> default_value;
    std::optional<TransferOwnership> ownership;

    InfoElements info_elements;
    AnyType type = static_cast<Type*>(nullptr);
};

struct Signal
{
    InfoAttributes info_attributes;
    std::string name;
    std::optional<bool> is_detailed;
    std::optional<RunSignal> when;
    std::optional<bool> is_action;
    std::optional<bool> no_hooks;
    std::optional<bool> no_recurse;
    std::optional<std::string> emitter;

    InfoElements info_elements;
    std::optional<CallableParams> params;
    std::optional<CallableReturn> return_type;
};

struct Record
{
    InfoAttributes info_attributes;
    std::string name;
    std::optional<std::string> c_type;
    std::optional<std::string> glib_type_name;
    std::optional<std::string> glib_type_func;
    std::optional<std::string> for_gtype_struct;
    std::optional<std::string> copy_function;
    std::optional<std::string> free_function;
    std::optional<bool> is_opaque;
    std::optional<bool> is_disguised_pointer;
    std::optional<bool> is_foreign;

    InfoElements info_elements;
    std::vector<Function> functions;
    std::vector<FunctionInline> inline_functions;
    std::vector<Method> methods;
    std::vector<MethodInline> inline_methods;
    std::vector<Constructor> constructors;
};

struct Prerequisite
{
    std::string name;
};

struct Implements
{
    std::string name;
};

struct Interface
{
    InfoAttributes info_attributes;
    std::string name;
    std::string glib_type_name;
    std::string glib_type_func;
    std::optional<std::string> c_type;
    std::optional<std::string> symbol_prefix;
    std::optional<std::string> glib_type_struct;

    InfoElements info_elements;
    std::vector<Prerequisite> prerequisites;
    std::vector<Implements> implements;
    std::vector<Function> functions;
    std::vector<FunctionInline> inline_functions;
    std::vector<Method> methods;
    std::vector<MethodInline> inline_methods;
    std::vector<VirtualMethod> virtual_methods;
    std::vector<Property> properties;
    std::vector<Signal> signals;

    std::optional<Constructor> constructor;
};

struct Class
{
    InfoAttributes info_attributes;
    std::string name;
    std::string glib_type_name;
    std::string glib_type_func;
    std::optional<std::string> parent;
    std::optional<std::string> glib_type_struct;
    std::optional<std::string> glib_ref_func;
    std::optional<std::string> glib_unref_func;
    std::optional<std::string> glib_set_value_func;
    std::optional<std::string> glib_get_value_func;
    std::optional<std::string> c_type;
    std::optional<std::string> symbol_prefix;
    std::optional<bool> is_abstract;
    std::optional<bool> is_glib_fundamental;
    std::optional<bool> is_final;

    InfoElements info_elements;
    std::vector<Implements> implements;
    std::vector<Constructor> constructors;
    std::vector<Method> methods;
    std::vector<MethodInline> inline_methods;
    std::vector<Function> functions;
    std::vector<FunctionInline> inline_functions;
    std::vector<VirtualMethod> virtual_methods;
    std::vector<Property> properties;
    std::vector<Signal> signals;
    std::vector<Record> records;
};

struct DocSection
{
    std::string name;
    DocElements doc_elements;
};

struct Namespace
{
    std::optional<std::string> name;
    std::optional<std::string> version;
    // Prefixes to filter out from C identifiers for data structures and types
    std::vector<std::string> identifier_prefixes;
    // Prefixes to filter out from C functions
    std::vector<std::string> symbol_prefixes;

    std::vector<Alias> aliases;
    std::vector<Class> classes;
    std::vector<Interface> interfaces;
    std::vector<Record> records;
    std::vector<Enum> enums;
    std::vector<Function> functions;
    std::vector<FunctionInline> inline_functions;
    std::vector<Bitfield> bitfields;
    std::vector<Annotation> annotations;
    std::vector<DocSection> doc_sections;

    // Types are not unique
    std::vector<std::unique_ptr<Type>> types;
    std::vector<std::unique_ptr<ArrayType>> array_types;
};

}  // namespace gir
