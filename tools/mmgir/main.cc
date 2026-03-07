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
#include "parse_gir.h"
#include "type_resolver.h"

#include <CLI/CLI.hpp>
#include <fmt/format.h>
#include <fmt/ranges.h>

#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <vector>

namespace fs = std::filesystem;

int main(int argc, char** argv)
{
    CLI::App app{"Generates C++ wrappers based on GObject introspection"};

    std::string gir_filepath;
    std::vector<std::string> supporting_girs;
    std::vector<std::string> search_paths;

    std::string enum_defs_filepath;
    std::string function_defs_filepath;
    std::string signal_defs_filepath;
    std::optional<std::string> vfunc_defs_filepath;

    bool warn_unknown = false;
    bool warn_ignored = false;
    bool warn_deprecated = false;

    auto is_gir_file = [](const std::string& arg) {
        if (fs::path(arg).extension() == GIR_EXT) {
            return "";
        } else {
            return "Not a GIR file";
        }
    };

    app.add_option("--gir", gir_filepath, "Input GIR filepath")
        ->required()
        ->check(CLI::ExistingFile)
        ->check(is_gir_file);
    app.add_option("--additional-gir", supporting_girs,
                   "Other GIR filepaths to help resolve types from other namespaces")
        ->check(CLI::ExistingFile)
        ->check(is_gir_file);
    app.add_option("--gir-search-dir", search_paths,
                   "Directories to search for missing GIR namespaces")
        ->check(CLI::ExistingDirectory);

    app.add_option("--enum-defs", enum_defs_filepath, "Output filepath for enum defs")
        ->required();
    app.add_option("--function-defs", function_defs_filepath,
                   "Output filepath for function/method defs")->required();
    app.add_option("--signal-defs", signal_defs_filepath,
                   "Output filepath for signal defs")->required();
    app.add_option("--vfunc-defs", vfunc_defs_filepath,
                   "Output filepath for virtual method defs");

    app.add_flag("--warn-unknown", warn_unknown, "Warn on unknown elements/attributes");
    app.add_flag("--warn-ignored", warn_ignored, "Warn on ignored elements/attributes");
    app.add_flag("--warn-deprecated", warn_deprecated,
                 "Warn on deprecated elements/attributes");

    CLI11_PARSE(app, argc, argv);

    const ParseArgs args{warn_unknown, warn_ignored, warn_deprecated};

    gir::Repository repo;
    try {
        repo = load_repository_from_file(gir_filepath, args);
    } catch (const GirParseError& e) {
        fmt::println(stderr, "ERROR: {}", e.what());
        return 1;
    }

    TypeResolver type_resolver;
    type_resolver.register_repo_types(repo);

    std::vector<gir::Repository> supporting_repos;
    try {
        load_supporting_repositories(supporting_girs, args, supporting_repos,
                                     type_resolver);
    } catch (const GirParseError& e) {
        fmt::println(stderr, "ERROR: {}", e.what());
        return 1;
    }

    try {
        search_for_included_namespaces(search_paths, args, repo, supporting_repos,
                                       type_resolver);
    } catch (const GirParseError& e) {
        fmt::println(stderr, "ERROR: {}", e.what());
        return 1;
    }

    if (type_resolver.has_unknown_types()) {
        // type_resolver.dump_mappings();
        type_resolver.dump_unknown_types();
        return 1;
    }

    {
        fmt::println("Dumping enum defs to {}", enum_defs_filepath);
        std::ofstream enum_defs_out(enum_defs_filepath);
        generate_extended_enum_defs(enum_defs_out, repo);
    }
    {
        fmt::println("Dumping function defs to {}", function_defs_filepath);
        std::ofstream function_defs_out(function_defs_filepath);
        generate_function_defs(function_defs_out, repo);
    }
    {
        fmt::println("Dumping signal defs to {}", signal_defs_filepath);
        std::ofstream signal_defs_out(signal_defs_filepath);
        generate_signal_defs(signal_defs_out, repo, type_resolver);
    }
    if (vfunc_defs_filepath) {
        fmt::println("Dumping vfunc defs to {}", *vfunc_defs_filepath);
        std::ofstream vfunc_defs_out(*vfunc_defs_filepath);
        generate_vfunc_defs(vfunc_defs_out, repo);
    }

    return 0;
}
