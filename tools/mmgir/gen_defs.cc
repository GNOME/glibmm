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

#include "gen_defs.h"

#include "type_resolver.h"

#include <fmt/format.h>
#include <fmt/ostream.h>
#include <fmt/ranges.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <regex>
#include <set>

using namespace gir;

namespace {

// Based on legacy def generation scripts (i.e. h2def.py), "none" is used in
// place of void for some return types
constexpr const char* NONE_RETURN = "none";
constexpr const char* VOID_RETURN = "void";

std::string flatten_any_type(const AnyType& any_type);

// A repo + namespace can have multiple prefixes applied to each type. Make the
// values unique and order from longest to shortest.
//
// The ordering is needed such that a shorter prefix doesn't prevent matching
// against a longer prefix. For example, G and GLib could both match for the
// prefix, but GLib is the better match.
std::vector<std::string_view> build_identifier_prefixes(const Repository& repo,
                                                        const Namespace& ns)
{
    struct LongestToShortest
    {
        bool operator()(std::string_view lhs, std::string_view rhs) const
        {
            return lhs.size() > rhs.size();
        }
    };

    std::set<std::string_view, LongestToShortest> unique_prefixes;
    for (const std::string& prefix : repo.identifier_prefixes) {
        unique_prefixes.insert(prefix);
    }
    for (const std::string& prefix : ns.identifier_prefixes) {
        unique_prefixes.insert(prefix);
    }

    return std::vector(unique_prefixes.begin(), unique_prefixes.end());
}

// Generates the GObject-style type casting macro name for a type.
//
// This involves a somewhat brittle heuristic transformation of the C type name
// using the conventions:
//
// GtkApplicationWindow          - PrefixNameInCamelCase
// GTK_TYPE_APPLICATION_WINDOW   - <PREFIX>_TYPE_<NAME_IN_UPPER_CAMEL_CASE>
std::string gen_c_type_cast(std::string_view c_type,
                            const std::vector<std::string_view>& prefixes)
{
    std::string result;

    auto it = std::find_if(prefixes.begin(), prefixes.end(),
                           [&](auto p) { return c_type.find(p) == 0; });
    size_t pos = 0;

    if (it != prefixes.end()) {
        // Use a known prefix
        for (unsigned char c : *it) {
            result += std::toupper(c);
        }
        result += "_TYPE_";

        c_type.remove_prefix(it->size());
    } else {
        // Assume the prefix is the first word and the rest of the type starts
        // from the second uppercase letter.
        for (pos = 1; pos < c_type.size(); pos++) {
            if (std::isupper(c_type[pos])) {
                break;
            }
        }

        for (size_t i = 0; i < pos; i++) {
            result += std::toupper(c_type[i]);
        }
        result += "_TYPE_";

        c_type.remove_prefix(pos - 1);
    }

    static const std::regex lower_to_upper_pat(R"(([^A-Z])([A-Z]))");
    static const std::regex acronyms_pattern(R"(([A-Z][A-Z])([A-Z][0-9a-z]))");

    // Insert _ on lowercase to uppercase transitions.
    // e.g. HelloWorld -> Hello_World
    std::string tmp = std::regex_replace(c_type.data(), lower_to_upper_pat, "$1_$2");
    // Break up acronyms detected from consecutive upper case characters.
    // e.g. IOChannel -> IO_Channel
    tmp = std::regex_replace(tmp.data(), acronyms_pattern, "$1_$2");

    for (unsigned char c : tmp) {
        result += std::toupper(c);
    }

    return result;
}

std::string convert_bool(const std::optional<bool>& value,
                         bool default_value)
{
    auto to_str = [](bool v) {
        return v ? "#t" : "#f";
    };

    if (!value) return to_str(default_value);
    else return to_str(*value);
}

// (define-enum DateDMY
//   (in-module "GLib")
//   (c-name "GDateDMY")
//   (values
//     '("day" "G_DATE_DAY")
//     '("month" "G_DATE_MONTH")
//     '("year" "G_DATE_YEAR")
//   )
// )

[[maybe_unused]]
void generate_enum_def(std::ostream& os, const Enum& enumeration,
                       const Namespace& ns)
{
    if (is_skippable(enumeration)) return;

    fmt::print(os, "(define-enum {}\n", enumeration.name);
    if (ns.name) {
        fmt::print(os, "  (in-module \"{}\")\n", *(ns.name));
    }
    fmt::print(os, "  (c-name \"{}\")\n", enumeration.c_type);
    // gtype-id is not useful for enums/flags
    fmt::print(os, "  (values\n");

    for (const Member& member : enumeration.members) {
        if (!member.nickname) {
            std::string converted_name = member.name;
            std::replace(converted_name.begin(), converted_name.end(), '_', '-');

            fmt::print(os, "    '(\"{}\" \"{}\")\n",
                       converted_name, member.c_identifier);
        } else {
            fmt::print(os, "    '(\"{}\" \"{}\")\n",
                       *(member.nickname), member.c_identifier);
        }
    }

    fmt::print(os, "  )\n");
    fmt::print(os, ")\n\n");
}

// (define-flags FileSetContentsFlags
//   (in-module "GLib")
//   (c-name "GFileSetContentsFlags")
//   (values
//     '("none" "G_FILE_SET_CONTENTS_NONE")
//     '("consistent" "G_FILE_SET_CONTENTS_CONSISTENT")
//     '("durable" "G_FILE_SET_CONTENTS_DURABLE")
//     '("only-existing" "G_FILE_SET_CONTENTS_ONLY_EXISTING")
//   )
// )

[[maybe_unused]]
void generate_bitfield_def(std::ostream& os, const Bitfield& bitfield,
                           const Namespace& ns)
{
    if (is_skippable(bitfield)) return;

    fmt::print(os, "(define-flags {}\n", bitfield.name);
    if (ns.name) {
        fmt::print(os, "  (in-module \"{}\")\n", *(ns.name));
    }
    fmt::print(os, "  (c-name \"{}\")\n", bitfield.c_type);
    // gtype-id is not useful for enums/flags
    fmt::print(os, "  (values\n");

    for (const Member& member : bitfield.members) {
        if (!member.nickname) {
            std::string converted_name = member.name;
            std::replace(converted_name.begin(), converted_name.end(), '_', '-');

            fmt::print(os, "    '(\"{}\" \"{}\")\n",
                       converted_name, member.c_identifier);
        } else {
            fmt::print(os, "    '(\"{}\" \"{}\")\n",
                       *(member.nickname), member.c_identifier);
        }
    }

    fmt::print(os, "  )\n");
    fmt::print(os, ")\n\n");
}

// (define-enum-extended AccessiblePlatformState
//   (in-module "Gtk")
//   (c-name "GtkAccessiblePlatformState")
//   (values
//     '("focusable" "GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE" "0")
//     '("focused" "GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED" "1")
//     '("active" "GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE" "2")
//   )
// )

void generate_extended_enum_def(std::ostream& os, const Enum& enumeration,
                                const std::optional<std::string>& namespace_name)
{
    if (is_skippable(enumeration)) return;

    fmt::print(os, "(define-enum-extended {}\n", enumeration.name);
    if (namespace_name) {
        fmt::print(os, "  (in-module \"{}\")\n", *namespace_name);
    }
    fmt::print(os, "  (c-name \"{}\")\n", enumeration.c_type);
    fmt::print(os, "  (values\n");

    if (std::any_of(enumeration.members.begin(), enumeration.members.end(),
                    [](const Member& m) { return !m.nickname; })) {
        fmt::println("WARN: Missing glib:nick for members in enum {}", enumeration.name);
    }

    for (const Member& member : enumeration.members) {
        if (!member.nickname) {
            std::string converted_name = member.name;
            std::replace(converted_name.begin(), converted_name.end(), '_', '-');

            fmt::print(os, "    '(\"{}\" \"{}\" \"{}\")\n",
                       converted_name, member.c_identifier, member.value);
        } else {
            fmt::print(os, "    '(\"{}\" \"{}\" \"{}\")\n",
                       *(member.nickname), member.c_identifier, member.value);
        }
    }

    fmt::print(os, "  )\n");
    fmt::print(os, ")\n\n");
}

// (define-flags-extended ListScrollFlags
//   (in-module "Gtk")
//   (c-name "GtkListScrollFlags")
//   (values
//     '("none" "GTK_LIST_SCROLL_NONE" "0x0")
//     '("focus" "GTK_LIST_SCROLL_FOCUS" "1 << 0")
//     '("select" "GTK_LIST_SCROLL_SELECT" "1 << 1")
//   )
// )

void generate_extended_bitfield_def(std::ostream& os, const Bitfield& bitfield,
                                    const std::optional<std::string>& namespace_name)
{
    if (is_skippable(bitfield)) return;

    fmt::print(os, "(define-flags-extended {}\n", bitfield.name);
    if (namespace_name) {
        fmt::print(os, "  (in-module \"{}\")\n", *namespace_name);
    }
    fmt::print(os, "  (c-name \"{}\")\n", bitfield.c_type);
    fmt::print(os, "  (values\n");

    if (std::any_of(bitfield.members.begin(), bitfield.members.end(),
                    [](const Member& m) { return !m.nickname; })) {
        fmt::println("WARN: Missing glib:nick for members in bitfield {}",
                     bitfield.name);
    }

    for (const Member& member : bitfield.members) {
        std::string converted_name = member.name;
        if (!member.nickname) {
            std::replace(converted_name.begin(), converted_name.end(), '_', '-');
        }

        std::string formatted_value;
        int n = std::atoi(member.value.c_str());
        // Use 1 << N format for flags (i.e. power of two values)
        if ((n > 0) && ((n & (n - 1)) == 0)) {
            int position = static_cast<int>(std::log2(static_cast<double>(n)));
            formatted_value = fmt::format("1 << {}", position);
        } else {
            // Format as hex with 0x prefix
            formatted_value = fmt::format("{:#x}", n);
        }

        fmt::print(os, "    '(\"{}\" \"{}\" \"{}\")\n",
                   converted_name, member.c_identifier, formatted_value);
    }

    fmt::print(os, "  )\n");
    fmt::print(os, ")\n\n");
}

std::string flatten_array_type(const ArrayType& type)
{
    if (type.c_type) {
        return *(type.c_type);
    } else {
        return flatten_any_type(type.element_type) + "*";
    }
}

std::string flatten_any_type(const AnyType& any_type)
{
    const auto visitor = overloads {
        [](const Type* type) -> std::string
        {
            if (type->c_type) {
                return *(type->c_type);
            } else if (type->name) {
                fmt::println(stderr, "ERROR: Using name of type with no C type: {}",
                             *(type->name));
                return *(type->name);
            } else {
                fmt::println(
                    stderr,
                    "ERROR: Using type with no name or C type! Falling back to void");
                return "void";
            }
        },
        [](const ArrayType* array_type) -> std::string
        {
            return flatten_array_type(*array_type);
        }
    };

    return std::visit(visitor, any_type);
}

struct ParamProcessor
{
    std::ostream& os;
    std::optional<std::reference_wrapper<const CallableAttributes>> attributes;
    std::vector<Param>::const_iterator curr;
    std::vector<Param>::const_iterator end;
    std::string_view func;
    bool has_var_args = false;

    ParamProcessor(std::ostream& out, const std::vector<Param>& params,
                   std::string_view func_name)
        : os(out), curr(params.begin()), end(params.end()), func(func_name)
    {}

    ParamProcessor(std::ostream& out, const CallableAttributes& attr,
                   const std::vector<Param>& params)
        : os(out), attributes(std::cref(attr)), curr(params.begin()), end(params.end()),
          func(attr.name)
    {}

    void print_param(std::string_view curr_indent, std::string_view single_indent);

    void maybe_print_var_args(std::string_view indent) const
    {
        if (has_var_args) {
            fmt::print(os, "{}(varargs #t)\n", indent);
        }
    }
};

std::string process_return_type(const std::optional<CallableReturn>& return_type,
                                const char* void_type)
{
    std::string converted;
    if (return_type) {
        converted = flatten_any_type(return_type->type);
        if (converted == VOID_RETURN) {
            converted = void_type;
        } else {
            std::replace(converted.begin(), converted.end(), ' ', '-');
        }
    } else {
        converted = void_type;
    }
    return converted;
}

// (define-function g_atomic_int_get
//   (c-name "g_atomic_int_get")
//   (return-type "gint")
//   (parameters
//     '("const-volatile-gint*" "atomic")
//   )
// )

void generate_func_def(std::ostream& os, const FunctionInline& func)
{
    if (is_skippable(func.attributes)) return;

    if (!func.attributes.c_identifier) {
        fmt::println(stderr, "ERROR: Free function '{}' has no C identifier",
                     func.attributes.name);
    }
    std::string_view func_name = func.attributes.c_identifier.value();

    fmt::print(os, "(define-function {}\n", func_name);
    fmt::print(os, "  (c-name \"{}\")\n", func_name);
    fmt::print(os, "  (return-type \"{}\")\n",
               process_return_type(func.return_type, NONE_RETURN));

    if (func.params) {
        ParamProcessor param_processor(os, func.attributes, func.params->params);
        param_processor.print_param("  ", "  ");
        param_processor.maybe_print_var_args("  ");
    }

    fmt::print(os, ")\n\n");
}

// (define-function gtk_icon_set_new_from_pixbuf
//   (c-name "gtk_icon_set_new_from_pixbuf"
//   (is-constructor-of "GtkIconSet"
//   (return-type "GtkIconSet*")
//   (parameters
//     '("GdkPixbuf*" "pixbuf")
//   )
// )

void generate_constructor_def(std::ostream& os, const Constructor& constructor,
                              std::string_view object)
{
    const FunctionInline& func = constructor.func.detail;
    if (is_skippable(func)) return;

    if (!func.attributes.c_identifier) {
        fmt::println(stderr, "ERROR: Constructor '{}' of '{}' has no C identifier",
                     func.attributes.name, object);
    }
    std::string_view func_name = func.attributes.c_identifier.value();

    fmt::print(os, "(define-function {}\n", func_name);
    fmt::print(os, "  (c-name \"{}\")\n", func_name);
    fmt::print(os, "  (is-constructor-of \"{}\")\n", object);
    fmt::print(os, "  (return-type \"{}\")\n",
               process_return_type(func.return_type, NONE_RETURN));

    if (func.params) {
        ParamProcessor param_processor(os, func.attributes, func.params->params);
        param_processor.print_param("  ", "  ");
        param_processor.maybe_print_var_args("  ");
    }

    fmt::print(os, ")\n\n");
}

// (define-method set_homogeneous
//   (of-object "GtkBox")
//   (c-name "gtk_box_set_homogeneous")
//   (return-type "none")
//   (parameters
//     '("gboolean" "homogeneous")
//   )
// )

void generate_method_def_using_func(std::ostream& os, const FunctionInline& func,
                                    std::string_view object)
{
    if (is_skippable(func)) return;

    if (!func.attributes.c_identifier) {
        fmt::println(stderr, "ERROR: Method '{}' of '{}' has no C identifier",
                     func.attributes.name, object);
    }
    std::string_view func_name = func.attributes.c_identifier.value();

    fmt::print(os, "(define-method {}\n", func.attributes.name);
    fmt::print(os, "  (of-object \"{}\")\n", object);
    fmt::print(os, "  (c-name \"{}\")\n", func_name);
    fmt::print(os, "  (return-type \"{}\")\n",
               process_return_type(func.return_type, NONE_RETURN));

    if (func.params) {
        ParamProcessor param_processor(os, func.attributes, func.params->params);
        param_processor.print_param("  ", "  ");
        param_processor.maybe_print_var_args("  ");
    }

    fmt::print(os, ")\n\n");
}

void generate_method_def(std::ostream& os, const MethodInline& method,
                         std::string_view object)
{
    generate_method_def_using_func(os, method.func.detail, object);
}

void generate_method_def(std::ostream& os, const Method& method,
                         std::string_view object)
{
    generate_method_def_using_func(os, method.func.detail, object);
}

// (define-vfunc set_current_uri
//   (of-object "GtkRecentChooser")
//   (return-type "gboolean")
//   (parameters
//     '("const-gchar*" "uri")
//     '("GError**" "error")
//   )
// )

void generate_vfunc_def(std::ostream& os, const VirtualMethod& vfunc,
                        std::string_view object)
{
    const FunctionInline& func = vfunc.func.detail;
    if (is_skippable(func)) return;

    std::string_view func_name = func.attributes.name;

    fmt::print(os, "(define-vfunc {}\n", func_name);
    fmt::print(os, "  (of-object \"{}\")\n", object);
    fmt::print(os, "  (return-type \"{}\")\n",
               process_return_type(func.return_type, VOID_RETURN));

    if (func.params) {
        ParamProcessor param_processor(os, func.attributes, func.params->params);
        param_processor.print_param("  ", "  ");
        param_processor.maybe_print_var_args("  ");
    }

    fmt::print(os, ")\n\n");
}

// (define-property program-name
//   (of-object "GtkAboutDialog")
//   (prop-type "GParamString")
//   (docs "")
//   (readable #t)
//   (writable #t)
//   (construct-only #f)
//   (default-value "")
// )

void generate_property_def(std::ostream& os, const Property& property,
                           std::string_view ns_name, std::string_view object,
                           const TypeResolver& type_resolver)
{
    if (is_skippable(property)) return;

    fmt::print(os, "(define-property {}\n", property.name);
    fmt::print(os, "  (of-object \"{}\")\n", object);

    std::optional<std::string> prop_type =
        type_resolver.find_property_type(property, ns_name);
    if (prop_type) {
        fmt::print(os, "  (prop-type \"{}\")\n", *prop_type);
    } else {
        fmt::println(stderr, "ERROR: Property '{}.{}:{}' has unresolved type: {}",
                     ns_name, object, property.name, flatten_any_type(property.type));
    }

    fmt::print(os, "  (docs \"\")\n");
    fmt::print(os, "  (readable {})\n", convert_bool(property.is_readable, true));
    fmt::print(os, "  (writable {})\n", convert_bool(property.is_writable, false));
    fmt::print(os, "  (construct-only {})\n",
               convert_bool(property.is_set_only_during_construction, false));
    if (property.default_value) {
        fmt::print(os, "  (default-value \"{}\")\n", *(property.default_value));
    }
    fmt::print(os, ")\n\n");
}

// (define-signal move-active
//   (of-object "GtkComboBox")
//   (return-type "void")
//   (flags "Run Last, No Recurse, No Hooks, Action")
//   (detailed #t)
//   (parameters
//     '("GtkScrollType" "p0")
//   )
// )

void generate_signal_def(std::ostream& os, const Signal& signal,
                         std::string_view object, std::string_view ns_name,
                         const TypeResolver& type_resolver)
{
    if (is_skippable(signal)) return;

    fmt::print(os, "(define-signal {}\n", signal.name);
    fmt::print(os, "  (of-object \"{}\")\n", object);
    std::optional<std::string> return_type =
        type_resolver.resolve_return_type(signal.return_type, ns_name);
    if (return_type) {
        std::replace(return_type->begin(), return_type->end(), ' ', '-');
        fmt::print(os, "  (return-type \"{}\")\n", *return_type);
    } else {
        fmt::println(stderr, "ERROR: Signal '{}.{}:{}' has unresolved return type",
                     ns_name, object, signal.name);
    }

    std::string flags;
    bool is_first_flag = true;

    auto add_comma = [&]() {
        if (!is_first_flag) {
            flags += ", ";
        }
        is_first_flag = false;
    };

    if (signal.when) {
        add_comma();
        switch (*(signal.when)) {
            case RunSignal::FIRST:
                flags += "Run First";
                break;
            case RunSignal::LAST:
                flags += "Run Last";
                break;
            case RunSignal::CLEANUP:
                flags += "Run Cleanup";
                break;
        }
    }
    if (signal.is_action) {
        add_comma();
        flags += "Action";
    }
    if (signal.no_hooks) {
        add_comma();
        flags += "No Hooks";
    }
    if (signal.no_recurse) {
        add_comma();
        flags += "No Recurse";
    }

    fmt::print(os, "  (flags \"{}\")\n", flags);
    if (signal.is_detailed) {
        fmt::print(os, "  (detailed {})\n", convert_bool(signal.is_detailed, false));
    }

    auto print_param = [&](const AnyType& any_type, std::string_view param_name) {
        std::optional<std::string> resolved =
            type_resolver.resolve_callable_param_type(any_type, ns_name);
        if (resolved) {
            std::replace(resolved->begin(), resolved->end(), ' ', '-');
            // All signal parameters that are registered as GTK_TYPE_STRING are
            // actually const gchar*..
            if (*resolved == "gchar*") {
                resolved = "const-gchar*";
            }
            fmt::print(os, "    '(\"{}\" \"{}\")\n", *resolved, param_name);
        } else {
            fmt::println(
                stderr, "ERROR: Signal '{}.{}:{}' has unresolved type for param '{}'",
                ns_name, object, signal.name, param_name);
        }
    };

    if (signal.params && signal.params->params.size() > 0) {
        fmt::print(os, "  (parameters\n");
        for (const Param& param : signal.params->params) {
            const auto visitor = overloads {
                [&](const AnyType& any_type) {
                    print_param(any_type, param.name.value());
                },
                [&](const VarArgs&) {}  // Signals can't have var args
            };
            std::visit(visitor, param.type.value());
        }
        fmt::print(os, "  )\n");
    }

    fmt::print(os, ")\n\n");
}

// (define-object Record
//   (in-module "Gtk")
//   (c-name "GtkRecord")
//   (gtype-id "GTK_TYPE_RECORD")
// )
template <class T>
void generate_standard_object_def(
    std::ostream& os,
    const T& obj,
    std::string_view type_name,
    const std::optional<std::string>& namespace_name,
    const std::vector<std::string_view>& identifier_prefixes)
{
    fmt::print(os, "(define-object {}\n", obj.name);
    if (namespace_name) {
        fmt::print(os, "  (in-module \"{}\")\n", *namespace_name);
    }
    fmt::print(os, "  (c-name \"{}\")\n", type_name);
    fmt::print(os, "  (gtype-id \"{}\")\n",
               gen_c_type_cast(type_name, identifier_prefixes));
    fmt::print(os, ")\n\n");
}

void generate_record_object_def(std::ostream& os, const Record& record,
                                const std::optional<std::string>& namespace_name,
                                const std::vector<std::string_view>& identifier_prefixes)
{
    if (is_skippable(record)) return;

    std::string_view c_type = record.c_type.value();
    generate_standard_object_def(os, record, c_type, namespace_name,
                                 identifier_prefixes);
}

void generate_interface_object_def(
    std::ostream& os,
    const Interface& interface,
    const std::optional<std::string>& namespace_name,
    const std::vector<std::string_view>& identifier_prefixes)
{
    if (is_skippable(interface)) return;

    std::string_view c_type = interface.glib_type_name;
    generate_standard_object_def(os, interface, c_type, namespace_name,
                                 identifier_prefixes);
}

void generate_class_object_def(
    std::ostream& os,
    const Class& klass,
    const std::optional<std::string>& namespace_name,
    const std::vector<std::string_view>& identifier_prefixes)
{
    if (is_skippable(klass)) return;

    std::string_view c_type = klass.glib_type_name;
    generate_standard_object_def(os, klass, c_type, namespace_name,
                                 identifier_prefixes);
}

template <class T>
void generate_free_function_defs(std::ostream&os, const T& obj)
{
    for (const auto& func : obj.inline_functions) {
        generate_func_def(os, func);
    }
    for (const auto& func : obj.functions) {
        generate_func_def(os, func.detail);
    }
}

template <class T>
void generate_standard_function_defs(std::ostream& os, const T& obj,
                                     std::string_view type_name)
{
    generate_free_function_defs(os, obj);

    for (const auto& method : obj.inline_methods) {
        generate_method_def(os, method, type_name);
    }
    for (const auto& method : obj.methods) {
        generate_method_def(os, method, type_name);
    }
}

void generate_record_function_defs(std::ostream& os, const Record& record)
{
    if (is_skippable(record)) return;

    if (!record.c_type) {
        fmt::println(stderr, "ERROR: Record {} with no C type", record.name);
    }
    std::string_view type_name = record.c_type.value();

    generate_standard_function_defs(os, record, type_name);

    for (const auto& func : record.constructors) {
        generate_constructor_def(os, func, type_name);
    }
}

void generate_interface_function_defs(std::ostream& os, const Interface& interface)
{
    if (is_skippable(interface)) return;

    std::string_view type_name = interface.glib_type_name;
    generate_standard_function_defs(os, interface, type_name);

    if (interface.constructor) {
        generate_constructor_def(os, *(interface.constructor), type_name);
    }
}

void generate_class_function_defs(std::ostream& os, const Class& klass)
{
    if (is_skippable(klass)) return;

    std::string_view type_name = klass.glib_type_name;
    generate_standard_function_defs(os, klass, type_name);

    for (const Constructor& constructor : klass.constructors) {
        generate_constructor_def(os, constructor, type_name);
    }
}

}  // namespace

void ParamProcessor::print_param(std::string_view curr_indent,
                                 std::string_view single_indent)
{
    const bool can_throw = attributes && attributes->get().can_throw.value_or(false);
    if ((curr == end) && !can_throw) return;

    fmt::print(os, "{}(parameters\n", curr_indent);
    for (; curr != end; curr++) {
        const Param& param = *curr;

        if (!param.type) {
            fmt::println(stderr, "ERROR: Free function '{}' has param with no type",
                         func);
        }

        const auto visitor = overloads {
            [&](const AnyType& any_type) {
                if (!param.name) {
                    fmt::println(stderr,
                                 "ERROR: Free function '{}' has param with no name",
                                 func);
                }

                std::string converted = flatten_any_type(any_type);
                std::replace(converted.begin(), converted.end(), ' ', '-');

                fmt::print(os, "{}{}'(\"{}\" \"{}\")\n", curr_indent, single_indent,
                           converted, param.name.value());
            },
            [&](const VarArgs&) { has_var_args = true; }
        };
        std::visit(visitor, param.type.value());
    }
    if (can_throw) {
        fmt::print(os, "{}{}'(\"GError**\" \"error\")\n", curr_indent, single_indent);
    }
    fmt::print(os, "{})\n", curr_indent);
}

void generate_extended_enum_defs(std::ostream& os, const Repository& repo)
{
    for (const Namespace& ns : repo.namespaces) {
        if (ns.name) {
            fmt::print(os, ";; Namespace {}\n", *(ns.name));
        } else {
            fmt::println("WARN: Missing name for namespace");
            fmt::print(os, ";; Namespace\n");
        }

        fmt::print(os, "\n;; Enums\n\n");
        for (const Enum& enumeration : ns.enums) {
            generate_extended_enum_def(os, enumeration, ns.name);
        }

        fmt::print(os, "\n;; Flags\n\n");
        for (const Bitfield& bitfield : ns.bitfields) {
            generate_extended_bitfield_def(os, bitfield, ns.name);
        }
    }
}

void generate_function_defs(std::ostream& os, const gir::Repository& repo)
{
    for (const Namespace& ns : repo.namespaces) {
        const std::string ns_name = ns.name.value_or("");
        const auto identifier_prefixes = build_identifier_prefixes(repo, ns);
        fmt::println("Identifier prefixes: {}", fmt::join(identifier_prefixes, ", "));
        if (identifier_prefixes.empty()) {
            fmt::println("WARN: No identifier prefixes provided!");
        }

        fmt::print(os, "\n;; Objects for namespace {}\n\n", ns_name);
        for (const Record& record : ns.records) {
            generate_record_object_def(os, record, ns.name, identifier_prefixes);
        }
        for (const Interface& interface : ns.interfaces) {
            generate_interface_object_def(os, interface, ns.name, identifier_prefixes);
        }
        for (const Class& klass : ns.classes) {
            generate_class_object_def(os, klass, ns.name, identifier_prefixes);
        }

        fmt::print(os, "\n;; Functions for namespace {}\n\n", ns_name);

        for (const FunctionInline& func : ns.inline_functions) {
            generate_func_def(os, func);
        }
        for (const Function& func : ns.functions) {
            generate_func_def(os, func.detail);
        }
        for (const Enum& enumeration : ns.enums) {
            generate_free_function_defs(os, enumeration);
        }
        for (const Bitfield& bitfield : ns.bitfields) {
            generate_free_function_defs(os, bitfield);
        }
        for (const Record& record : ns.records) {
            generate_record_function_defs(os, record);
        }
        for (const Interface& interface : ns.interfaces) {
            generate_interface_function_defs(os, interface);
        }
        for (const Class& klass : ns.classes) {
            generate_class_function_defs(os, klass);
        }
    }
}

void generate_signal_defs(std::ostream& os, const gir::Repository& repo,
                          const TypeResolver& type_resolver)
{
    for (const Namespace& ns : repo.namespaces) {
        const std::string ns_name = ns.name.value_or("");

        for (const Interface& interface : ns.interfaces) {
            if (is_skippable(interface)) continue;

            for (const Property& property : interface.properties) {
                generate_property_def(os, property, ns_name, interface.glib_type_name,
                                      type_resolver);
            }

            for (const Signal& signal : interface.signals) {
                generate_signal_def(os, signal, interface.glib_type_name, ns_name,
                                    type_resolver);
            }
        }

        for (const Class& klass : ns.classes) {
            if (is_skippable(klass)) continue;

            for (const Property& property : klass.properties) {
                generate_property_def(os, property, ns_name, klass.glib_type_name,
                                      type_resolver);
            }

            for (const Signal& signal : klass.signals) {
                generate_signal_def(os, signal, klass.glib_type_name, ns_name,
                                    type_resolver);
            }
        }
    }
}

void generate_vfunc_defs(std::ostream& os, const gir::Repository& repo)
{
    for (const Namespace& ns : repo.namespaces) {
        for (const Interface& interface : ns.interfaces) {
            if (is_skippable(interface)) continue;

            for (const VirtualMethod& vfunc : interface.virtual_methods) {
                generate_vfunc_def(os, vfunc, interface.glib_type_name);
            }
        }

        for (const Class& klass : ns.classes) {
            if (is_skippable(klass)) continue;

            for (const VirtualMethod& vfunc : klass.virtual_methods) {
                generate_vfunc_def(os, vfunc, klass.glib_type_name);
            }
        }
    }
}
