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

#include <stdexcept>
#include <string>
#include <string_view>

class TypeResolver;

struct GirParseError : std::runtime_error {
    explicit GirParseError(const std::string& msg) : std::runtime_error(msg) {}
};

struct ParseArgs {
    bool warn_unknown = false;
    bool warn_ignored = false;
    bool warn_deprecated = false;
};

constexpr const char* const GIR_EXT = ".gir";

gir::Repository load_repository_from_file(std::string_view filepath,
                                          const ParseArgs& args);

void load_supporting_repositories(const std::vector<std::string>& paths,
                                  const ParseArgs& args,
                                  std::vector<gir::Repository>& supporting_repos,
                                  TypeResolver& type_resolver);

void search_for_included_namespaces(const std::vector<std::string>& paths,
                                    const ParseArgs& args,
                                    const std::vector<gir::Repository>& input_repos,
                                    std::vector<gir::Repository>& supporting_repos,
                                    TypeResolver& type_resolver);
