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

#include <fmt/color.h>
#include <fmt/format.h>

enum class LogLevel { INFO, WARN, ERROR };

// Compile-time checked format strings in C++17
template <class... Args>
std::string format(fmt::format_string<Args...> fmt, Args&&... args) {
    return fmt::format(fmt, std::forward<Args>(args)...);
}

template <class... Args>
void log(LogLevel level, fmt::format_string<Args...> fmt_str, Args&&... args) {
    auto message = fmt::format(fmt_str, std::forward<Args>(args)...);

    switch (level) {
        case LogLevel::ERROR:
            fmt::print(stderr, fmt::fg(fmt::color::red) | fmt::emphasis::bold,
                       "[ERROR] ");
            fmt::println(stderr, fmt_str, std::forward<Args>(args)...);
            break;
        case LogLevel::WARN:
            fmt::print(fmt::fg(fmt::color::yellow) | fmt::emphasis::bold, "[WARN] ");
            fmt::println(fmt_str, std::forward<Args>(args)...);
            break;
        case LogLevel::INFO:
        default:
            fmt::println(fmt_str, std::forward<Args>(args)...);
            break;
    }
}

#define LOG_WARN(msg) log(LogLevel::WARN, msg);
#define LOG_WARNV(msg, ...) log(LogLevel::WARN, msg, __VA_ARGS__);

#define LOG_ERROR(msg) log(LogLevel::ERROR, msg);
#define LOG_ERRORV(msg, ...) log(LogLevel::ERROR, msg, __VA_ARGS__);
