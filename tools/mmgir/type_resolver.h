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

#include "schema.h"

#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <string_view>

class TypeMapper;

template <class T>
using StringMap = std::map<std::string, T, std::less<>>;

enum class GParam {
    BOOLEAN,
    BOXED,
    CHAR,
    DOUBLE,
    ENUM,
    FLAGS,
    FLOAT,
    GTYPE,
    INT,
    INT64,
    LONG,
    OBJECT,
    POINTER,
    STRING,
    UCHAR,
    UINT,
    UINT64,
    ULONG,
    UNICHAR,
    VARIANT,
    // Not applicable
    NA
};

class TypeResolver
{
public:
    struct TypeInfo {
        std::string c_type;
        GParam param_spec = GParam::NA;
    };

    TypeResolver();

    void register_repo_types(const gir::Repository& repo);

    std::optional<std::string> find_property_type(const gir::Property& property,
                                                  std::string_view namespace_name) const;

    bool is_builtin_type(std::string_view name) const;
    bool has_unknown_types() const { return m_unknown_types.size() > 0; }
    // Returns namespace names of unknown types
    std::set<std::string> missing_namespaces() const;

    void dump_mappings() const;
    void dump_unknown_types() const;

private:
    friend class TypeMapper;

    std::optional<std::string> find_type(
        const gir::Type* type, std::string_view namespace_name) const;

    static const StringMap<std::string> s_builtin_type_to_c_type;
    static const StringMap<GParam> s_builtin_name_to_g_param;

    StringMap<TypeInfo> m_name_to_type_info;
    std::set<std::string, std::less<>> m_unknown_types;
    bool m_has_errors;
};
