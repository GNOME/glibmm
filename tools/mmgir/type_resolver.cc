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

#include "mmgir.h"

#include "type_resolver.h"

#include <fmt/format.h>

#include <map>
#include <set>

#define RECORD_ERROR(msg) \
    m_has_errors = true; \
    LOG_ERROR(msg);

#define RECORD_ERRORV(fmt_str, ...) \
    m_has_errors = true; \
    LOG_ERRORV(fmt_str, __VA_ARGS__);

using namespace gir;

namespace {

constexpr std::string_view VOID_TYPE = "void";

std::string to_string(GParam spec)
{
    switch (spec) {
        case GParam::BOOLEAN:
            return "GParamBoolean";
        case GParam::BOXED:
            return "GParamBoxed";
        case GParam::CHAR:
            return "GParamChar";
        case GParam::DOUBLE:
            return "GParamDouble";
        case GParam::ENUM:
            return "GParamEnum";
        case GParam::FLAGS:
            return "GParamFlags";
        case GParam::FLOAT:
            return "GParamFloat";
        case GParam::GTYPE:
            return "GParamGType";
        case GParam::INT:
            return "GParamInt";
        case GParam::INT64:
            return "GParamInt64";
        case GParam::LONG:
            return "GParamLong";
        case GParam::OBJECT:
            return "GParamObject";
        case GParam::POINTER:
            return "GParamPointer";
        case GParam::STRING:
            return "GParamString";
        case GParam::UCHAR:
            return "GParamUChar";
        case GParam::UINT:
            return "GParamUInt";
        case GParam::UINT64:
            return "GParamUInt64";
        case GParam::ULONG:
            return "GParamULong";
        case GParam::UNICHAR:
            return "GParamUnichar";
        case GParam::VARIANT:
            return "GParamVariant";
        case GParam::NA:
            return "(n/a)";
        default:
            throw std::runtime_error("Unknown GParam");
    }
}

std::string qualify_non_builtin_name(std::string_view name,
                                     std::string_view namespace_name)
{
    std::string qualified_name;
    if (name.find('.') == std::string_view::npos) {
        qualified_name = fmt::format("{}.{}", namespace_name, name);
    } else {
        qualified_name = name;
    }
    return qualified_name;
}

}  // namespace

class TypeMapper
{
public:
    TypeMapper(const Namespace& ns, TypeResolver& resolver);

private:
    bool is_qualified_name(std::string_view name) const;
    std::string qualify_name(std::string_view name) const;
    void record_mapping(std::string_view name, std::string_view c_type,
                        GParam param_spec);
    void record_unknown(std::string_view name);

    void extract_simple_types();
    void extract_property_types();

    void find_unknown_types();
    void find_unknown_types_for_callable(
        const std::optional<CallableParams>& params,
        const std::optional<CallableReturn>& return_type);
    void find_unknown_types_for_any_type(const AnyType& any_type);

    std::string m_namespace_name;
    const Namespace& m_namespace;
    TypeResolver& m_resolver;
    bool& m_has_errors;
};

TypeMapper::TypeMapper(const Namespace& ns, TypeResolver& resolver)
    : m_namespace_name(ns.name.value()),
      m_namespace(ns),
      m_resolver(resolver),
      m_has_errors(resolver.m_has_errors)
{
    extract_simple_types();
    find_unknown_types();

    extract_property_types();
}

bool TypeMapper::is_qualified_name(std::string_view name) const
{
    if (m_resolver.is_builtin_type(name)) return true;

    return name.find('.') != std::string_view::npos;
}

std::string TypeMapper::qualify_name(std::string_view name) const
{
    std::string qualified_name;
    if (!is_qualified_name(name)) {
        qualified_name = fmt::format("{}.{}", m_namespace_name, name);
    } else {
        qualified_name = name;
    }
    return qualified_name;
}

void TypeMapper::record_mapping(std::string_view name,
                                std::string_view c_type,
                                GParam param_spec)
{
    std::string qualified_name = qualify_name(name);

    auto it = m_resolver.m_name_to_type_info.find(qualified_name);
    if (it != m_resolver.m_name_to_type_info.end()) {
        if (it->second.c_type != c_type) {
            RECORD_ERRORV("Type '{}' has inconsistent C types:", qualified_name);
            RECORD_ERRORV("  {}", it->second.c_type);
            RECORD_ERRORV("  {}", c_type);
        }
    } else {
        m_resolver.m_name_to_type_info.emplace(
            qualified_name, TypeResolver::TypeInfo{std::string{c_type}, param_spec});
    }

    m_resolver.m_unknown_types.erase(qualified_name);
}

void TypeMapper::record_unknown(std::string_view name)
{
    if (m_resolver.is_builtin_type(name)) return;

    std::string qualified_name = qualify_name(name);
    auto it = m_resolver.m_name_to_type_info.find(qualified_name);
    if (it == m_resolver.m_name_to_type_info.end()) {
        m_resolver.m_unknown_types.insert(qualified_name);
    }
}

void TypeMapper::extract_simple_types()
{
    for (const Alias& alias : m_namespace.aliases) {
        record_mapping(alias.name, alias.c_type, GParam::NA);
    }
    for (const Enum& enumeration : m_namespace.enums) {
        record_mapping(enumeration.name, enumeration.c_type, GParam::ENUM);
    }
    for (const Bitfield& bitfield : m_namespace.bitfields) {
        record_mapping(bitfield.name, bitfield.c_type, GParam::FLAGS);
    }
    for (const Union& plain_union : m_namespace.unions) {
        if (plain_union.name && plain_union.c_type) {
            record_mapping(*(plain_union.name), *(plain_union.c_type), GParam::BOXED);
        }
    }
    for (const Record& record : m_namespace.records) {
        if (record.c_type) {
            record_mapping(record.name, *(record.c_type), GParam::BOXED);
        }
    }
    for (const Interface& interface : m_namespace.interfaces) {
        record_mapping(interface.name, interface.glib_type_name, GParam::OBJECT);
    }
    for (const Class& klass : m_namespace.classes) {
        record_mapping(klass.name, klass.glib_type_name, GParam::OBJECT);
    }
}

void TypeMapper::find_unknown_types()
{
    auto find_for_inline_function = [&](const FunctionInline& func) {
        if (is_skippable(func)) return;

        find_unknown_types_for_callable(func.params, func.return_type);
    };
    auto find_for_functions = [&](const auto& obj) {
        for (const FunctionInline& func : obj.inline_functions) {
            find_for_inline_function(func);
        }

        for (const Function& func : obj.functions) {
            find_for_inline_function(func.detail);
        }
    };
    auto find_for_constructors = [&](const auto& obj) {
        for (const Constructor& constructor : obj.constructors) {
            find_for_inline_function(constructor.func.detail);
        }
    };
    auto find_for_methods = [&](const auto& obj) {
        for (const MethodInline& method : obj.inline_methods) {
            find_for_inline_function(method.func.detail);
        }

        for (const Method& method : obj.methods) {
            find_for_inline_function(method.func.detail);
        }
    };
    auto find_for_virtual_methods = [&](const auto& obj) {
        for (const VirtualMethod& method : obj.virtual_methods) {
            find_for_inline_function(method.func.detail);
        }
    };

    find_for_functions(m_namespace);

    for (const Enum& enumeration : m_namespace.enums) {
        if (is_skippable(enumeration)) continue;

        find_for_functions(enumeration);
    }

    for (const Bitfield& bitfield : m_namespace.bitfields) {
        if (is_skippable(bitfield)) continue;

        find_for_functions(bitfield);
    }

    auto find_for_union = [&](const Union& plain_union) {
        if (is_skippable(plain_union)) return;

        find_for_functions(plain_union);
        find_for_methods(plain_union);
        find_for_constructors(plain_union);
    };
    for (const Union& plain_union : m_namespace.unions) {
        find_for_union(plain_union);
    }

    auto find_for_record = [&](const Record& record) {
        if (is_skippable(record)) return;

        find_for_functions(record);
        find_for_methods(record);
        find_for_constructors(record);
    };
    for (const Record& record : m_namespace.records) {
        find_for_record(record);
    }

    for (const Interface& interface : m_namespace.interfaces) {
        if (is_skippable(interface)) continue;

        find_for_functions(interface);
        find_for_methods(interface);
        find_for_virtual_methods(interface);
        if (interface.constructor) {
            find_for_inline_function(interface.constructor->func.detail);
        }
    }

    for (const Class& klass : m_namespace.classes) {
        if (is_skippable(klass)) continue;

        find_for_functions(klass);
        find_for_methods(klass);
        find_for_virtual_methods(klass);
        find_for_constructors(klass);
        for (const Union& plain_union : klass.unions) {
            find_for_union(plain_union);
        }
        for (const Record& record : klass.records) {
            find_for_record(record);
        }
    }
}

void TypeMapper::find_unknown_types_for_callable(
    const std::optional<CallableParams>& params,
    const std::optional<CallableReturn>& return_type)
{
    if (params) {
        for (const Param& p : params->params) {
            if (!p.type) continue;
            if (p.is_skippable.value_or(false)) continue;
            if (!std::holds_alternative<AnyType>(*(p.type))) continue;

            find_unknown_types_for_any_type(std::get<AnyType>(*(p.type)));
        }
        // Ignore instance params since they must be part of an object that
        // is already defined
    }

    if (return_type && !return_type->is_skippable.value_or(false)) {
        find_unknown_types_for_any_type(return_type->type);
    }
}

void TypeMapper::find_unknown_types_for_any_type(const AnyType& any_type)
{
    auto record_type = [&](auto type) {
        if (!type->c_type && type->name) {
            record_unknown(*(type->name));
        }
    };

    const auto visitor = overloads {
        [&](const Type* type) {
            record_type(type);
        },
        [&](const ArrayType* array) {
            // Arrays with no name don't get recorded
            record_type(array);
            find_unknown_types_for_any_type(array->element_type);
        }
    };

    std::visit(visitor, any_type);
}

void TypeMapper::extract_property_types()
{
    for (const Interface& interface : m_namespace.interfaces) {
        if (is_skippable(interface)) continue;

        for (const Property& property : interface.properties) {
            if (is_skippable(property)) continue;

            find_unknown_types_for_any_type(property.type);
        }
    }
    for (const Class& klass : m_namespace.classes) {
        if (is_skippable(klass)) continue;

        for (const Property& property : klass.properties) {
            if (is_skippable(property)) continue;

            find_unknown_types_for_any_type(property.type);
        }
    }
}

const StringMap<std::string> TypeResolver::s_builtin_type_to_c_type = {
    {"GType", "GType"},
    {"gboolean", "gboolean"},

    {"gsize", "gsize"},
    {"gssize", "gssize"},
    {"goffset", "goffset"},
    {"gpointer", "gpointer"},
    {"gconstpointer", "gconstpointer"},
    {"gintptr", "gintptr"},
    {"guintptr", "guintptr"},

    {"gchar", "gchar"},
    {"gint", "gint"},
    {"gshort", "glong"},
    {"glong", "glong"},
    {"gfloat", "gfloat"},
    {"gdouble", "gdouble"},

    {"guchar", "guchar"},
    {"guint", "guint"},
    {"gushort", "gulong"},
    {"gulong", "gulong"},

    {"gint8", "gint8"},
    {"gint16", "gint16"},
    {"gint32", "gint32"},
    {"gint64", "gint64"},
    {"guint8", "guint8"},
    {"guint16", "guint16"},
    {"guint32", "guint32"},
    {"guint64", "guint64"},

    {"gunichar", "gunichar"},
    {"utf8", "const gchar*"},
    {"filename", "const gchar*"},
    {"va_list", "va_list"},

    // Special types from observed data
    {"time_t", "time_t"},
    {"none", "void"},
};

const StringMap<GParam> TypeResolver::s_builtin_name_to_g_param = {
    {"GType", GParam::GTYPE},
    {"gboolean", GParam::BOOLEAN},

    {"gpointer", GParam::POINTER},
    {"gconstpointer", GParam::POINTER},

    {"gchar", GParam::CHAR},
    {"gint", GParam::INT},
    {"gshort", GParam::INT},
    {"glong", GParam::LONG},
    {"gfloat", GParam::FLOAT},
    {"gdouble", GParam::DOUBLE},

    {"guchar", GParam::UCHAR},
    {"guint", GParam::UINT},
    {"gushort", GParam::UINT},
    {"gulong", GParam::ULONG},

    {"gint8", GParam::INT},
    {"gint16", GParam::INT},
    {"gint32", GParam::INT},
    {"gint64", GParam::INT64},
    {"guint8", GParam::UINT},
    {"guint16", GParam::UINT},
    {"guint32", GParam::UINT},
    {"guint64", GParam::UINT64},

    {"gunichar", GParam::UNICHAR},
    {"utf8", GParam::STRING},
    {"filename", GParam::STRING},

    {"GLib.Variant", GParam::VARIANT},
};

TypeResolver::TypeResolver() : m_has_errors(false)
{
}

void TypeResolver::register_repo_types(const Repository& repo)
{
    for (const auto& ns : repo.namespaces) {
        if (!ns.name) {
            RECORD_ERROR("Skipping namespace without name");
            continue;
        }

        TypeMapper mapper(ns, *this);
    }
}

std::set<std::string> TypeResolver::missing_namespaces() const
{
    std::set<std::string> missing;
    for (const std::string& qualified_name : m_unknown_types) {
        size_t pos = qualified_name.find('.');
        if (pos != std::string::npos) {
            missing.insert(qualified_name.substr(0, pos));
        }
    }
    return missing;
}

std::optional<std::string> TypeResolver::resolve_any_type(
    const gir::AnyType& any_type, std::string_view namespace_name) const
{
    std::optional<std::string> result;

    const auto visitor = overloads {
        [&](const Type* type) {
            result = find_type(type, namespace_name);
        },
        [&](const ArrayType* array) {
            if (array->c_type) {
                result = array->c_type;
            } else {
                std::optional<std::string> element_type =
                    resolve_any_type(array->element_type, namespace_name);
                if (element_type) {
                    result = *element_type + "*";
                }
            }
        }
    };
    std::visit(visitor, any_type);

    return result;
}

std::optional<std::string> TypeResolver::resolve_callable_param_type(
    const gir::AnyType& param, std::string_view namespace_name) const
{
    std::optional<std::string> result;

    auto append_pointer = [&](const Type* type) {
        if (!result) return;
        if (type->c_type) return;

        std::string_view name = type->name.value();
        if (is_builtin_type(name)) return;

        std::string qualified_name = qualify_non_builtin_name(name, namespace_name);

        auto it = m_name_to_type_info.find(qualified_name);
        if (it != m_name_to_type_info.end()) {
            switch (it->second.param_spec) {
                case GParam::BOXED:
                case GParam::OBJECT:
                    *result += "*";
                    break;
                default:
                    break;
            }
        } else {
            result = std::nullopt;
        }
    };

    const auto visitor = overloads {
        [&](const Type* type) {
            result = find_type(type, namespace_name);
            append_pointer(type);
        },
        [&](const ArrayType* array) {
            if (array->c_type) {
                result = array->c_type;
            } else {
                std::optional<std::string> element_type =
                    resolve_any_type(array->element_type, namespace_name);
                if (element_type) {
                    result = *element_type + "*";
                }
            }
        }
    };
    std::visit(visitor, param);

    return result;
}

std::optional<std::string> TypeResolver::resolve_return_type(
    std::optional<gir::CallableReturn> callable_return,
    std::string_view namespace_name,
    std::optional<std::string_view> void_type) const
{
    std::optional<std::string> result;
    if (!callable_return) {
        result = VOID_TYPE;
    } else {
        result = resolve_any_type(callable_return->type, namespace_name);
    }

    if (void_type && result && *result == VOID_TYPE) {
        result = *void_type;
    }

    return result;
}

std::optional<std::string> TypeResolver::find_property_type(
    const Property& property, std::string_view namespace_name) const
{
    std::optional<std::string> result;

    const auto visitor = overloads {
        [&](const Type* type) {
            if (type->name) {
                std::string_view name = *(type->name);

                auto builtin_it = s_builtin_name_to_g_param.find(name);
                if (builtin_it != s_builtin_name_to_g_param.end()) {
                    result = to_string(builtin_it->second);
                } else {
                    std::string qualified_name =
                        qualify_non_builtin_name(name, namespace_name);

                    auto it = m_name_to_type_info.find(qualified_name);
                    if (it != m_name_to_type_info.end()) {
                        result = to_string(it->second.param_spec);
                    }
                }
            }
        },
        [&](const ArrayType* /* array */) {
            result = to_string(GParam::BOXED);
        }
    };
    std::visit(visitor, property.type);

    return result;
}

std::optional<std::string> TypeResolver::find_type(
    const Type* type, std::string_view namespace_name) const
{
    std::optional<std::string> result;

    if (type->c_type) {
        result = *(type->c_type);
    } else if (type->name) {
        std::string_view gtype = *(type->name);

        auto builtin_it = s_builtin_type_to_c_type.find(gtype);
        if (builtin_it != s_builtin_type_to_c_type.end()) {
            result = builtin_it->second;
        } else {
            std::string qualified_name = qualify_non_builtin_name(gtype, namespace_name);

            auto it = m_name_to_type_info.find(qualified_name);
            if (it != m_name_to_type_info.end()) {
                result = it->second.c_type;
            }
        }
    }

    return result;
}

bool TypeResolver::is_builtin_type(std::string_view name) const
{
    return s_builtin_type_to_c_type.find(name) != s_builtin_type_to_c_type.end();
}

void TypeResolver::dump_mappings() const
{
    fmt::println("Type Mappings");
    for (const auto& [name, info] : m_name_to_type_info) {
        fmt::println("  GType: {}", name);
        fmt::println("      C: {}", info.c_type);
        fmt::println("   Spec: {}", to_string(info.param_spec));
    }
}

void TypeResolver::dump_unknown_types() const
{
    if (m_unknown_types.size() == 0) {
        fmt::println("No unknown type mappings");
        return;
    }

    fmt::println("Unknown Type Mappings");
    for (const auto& name : m_unknown_types) {
        fmt::println("  {}", name);
    }
}
