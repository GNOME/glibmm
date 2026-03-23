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

#include <catch2/catch_test_macros.hpp>
#include <fmt/format.h>

TEST_CASE("bitfield with no bits set", "[gen_defs]")
{
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "0");
    REQUIRE(result);
    REQUIRE(*result == "0x0");
}

TEST_CASE("bitfield (1 << 0)", "[gen_defs]")
{
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "1");
    REQUIRE(result);
    REQUIRE(*result == "1 << 0");
}

TEST_CASE("bitfield (1 << 6)", "[gen_defs]")
{
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "64");
    REQUIRE(result);
    REQUIRE(*result == "1 << 6");
}

TEST_CASE("bitfield with multiple bits set", "[gen_defs]")
{
    // (1 << 0) | (1 << 3) | (1 << 7)
    constexpr std::string_view value = "137";

    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", value);
    REQUIRE(result);
    REQUIRE(*result == "0x89");
}

TEST_CASE("bitfield with max bit set", "[gen_defs]")
{
    // From GObject-2.0.gir G_PARAM_DEPRECATED
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "2147483648");
    REQUIRE(result);
    REQUIRE(*result == "1 << 31");
}

TEST_CASE("bitfield with negative value and single bit set", "[gen_defs]")
{
    // From GLib-2.0.gir G_LOG_LEVEL_MASK
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "-56");
    REQUIRE(result);
    REQUIRE(*result == "-0x38");
}

TEST_CASE("bitfield with negative value and multiple bits set", "[gen_defs]")
{
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "-4");
    REQUIRE(result);
    REQUIRE(*result == "-0x4");
}

TEST_CASE("bitfield with out of range value (1 << 32)", "[gen_defs]")
{
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "4294967296");
    REQUIRE(!result);
}

TEST_CASE("bitfield with out of range negative value -(1 << 31)", "[gen_defs]")
{
    std::optional<std::string> result = format_bitfield_members(
        "bitfield", "member", "-2147483648");
    REQUIRE(!result);
}
