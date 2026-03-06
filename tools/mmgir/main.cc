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

#include <CLI/CLI.hpp>
#include <fmt/format.h>

#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <vector>

namespace fs = std::filesystem;

bool has_gir_extension(const std::string& arg)
{
    return fs::path(arg).extension() == ".gir";
}

int main(int argc, char** argv)
{
    CLI::App app{"Generates C++ wrappers based on GObject introspection"};

    std::string gir_filepath;
    std::vector<std::string> supporting_girs;
    std::vector<std::string> gir_search_paths;

    std::string enum_defs_filepath;
    std::string function_defs_filepath;
    std::string signal_defs_filepath;
    std::optional<std::string> vfunc_defs_filepath;

    bool warn_unknown = false;
    bool warn_ignored = false;
    bool warn_deprecated = false;

    app.add_option("--gir", gir_filepath, "Input GIR filepath")
        ->required()
        ->check(CLI::ExistingFile)
        ->check([](const std::string& arg) {
                if (has_gir_extension(arg)) {
                    return "";
                } else {
                    return "Not a GIR file";
                }
            });

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

    gir::Repository repo;
    try {
        fmt::println("Reading {}", gir_filepath);
        ParseArgs args{gir_filepath, warn_unknown, warn_ignored, warn_deprecated};
        repo = load_repository_from_file(args);
    } catch (const GirParseError& e) {
        fmt::println(stderr, "ERROR: {}", e.what());
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
        generate_signal_defs(signal_defs_out, repo);
    }
    if (vfunc_defs_filepath) {
        fmt::println("Dumping vfunc defs to {}", *vfunc_defs_filepath);
        std::ofstream vfunc_defs_out(*vfunc_defs_filepath);
        generate_vfunc_defs(vfunc_defs_out, repo);
    }

    return 0;
}
