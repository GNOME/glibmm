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

#include <iostream>
#include <optional>
#include <string_view>

class TypeResolver;

void generate_extended_enum_defs(std::ostream& os, const gir::Repository& repo);
void generate_function_defs(std::ostream& os, const gir::Repository& repo);
void generate_signal_defs(std::ostream& os, const gir::Repository& repo,
                          const TypeResolver& type_resolver);
void generate_vfunc_defs(std::ostream& os, const gir::Repository& repo);

// Exposed for unit testing purposes

std::optional<std::string> format_bitfield_members(
    std::string_view bitfield_name,
    std::string_view member_name,
    std::string_view member_value);
