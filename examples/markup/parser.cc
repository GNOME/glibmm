/* Copyright (C) 2002 The gtkmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm.h>
#include <iomanip>
#include <iostream>

namespace
{

void
file_get_contents(const std::string& filename, Glib::ustring& contents)
{
  const auto channel = Glib::IOChannel::create_from_file(filename, "r");
  channel->read_to_end(contents);
}

Glib::ustring
trim_whitespace(const Glib::ustring& text)
{
  Glib::ustring::const_iterator pbegin(text.begin());
  Glib::ustring::const_iterator pend(text.end());

  while (pbegin != pend && Glib::Unicode::isspace(*pbegin))
    ++pbegin;

  Glib::ustring::const_iterator temp(pend);

  while (pbegin != temp && Glib::Unicode::isspace(*--temp))
    pend = temp;

  return Glib::ustring(pbegin, pend);
}

class DumpParser : public Glib::Markup::Parser
{
public:
  DumpParser();
  ~DumpParser() override;

protected:
  void on_start_element(Glib::Markup::ParseContext& context, const Glib::ustring& element_name,
    const AttributeMap& attributes) override;

  void on_end_element(
    Glib::Markup::ParseContext& context, const Glib::ustring& element_name) override;

  void on_text(Glib::Markup::ParseContext& context, const Glib::ustring& text) override;

private:
  int parse_depth_;

  void indent();
};

DumpParser::DumpParser() : parse_depth_(0)
{
}

DumpParser::~DumpParser()
{
}

void
DumpParser::on_start_element(
  Glib::Markup::ParseContext&, const Glib::ustring& element_name, const AttributeMap& attributes)
{
  indent();
  std::cout << '<' << element_name;

  for (const auto& p : attributes)
  {
    std::cout << ' ' << p.first << "=\"" << p.second << '"';
  }

  std::cout << ">\n";

  ++parse_depth_;
}

void
DumpParser::on_end_element(Glib::Markup::ParseContext&, const Glib::ustring& element_name)
{
  --parse_depth_;

  indent();
  std::cout << "</" << element_name << ">\n";
}

void
DumpParser::on_text(Glib::Markup::ParseContext&, const Glib::ustring& text)
{
  const Glib::ustring trimmed_text = trim_whitespace(text);

  if (!trimmed_text.empty())
  {
    indent();
    std::cout << trimmed_text << '\n';
  }
}

void
DumpParser::indent()
{
  if (parse_depth_ > 0)
  {
    std::cout << std::setw(4 * parse_depth_)
              /* gcc 2.95.3 doesn't like this: << std::right */
              << ' ';
  }
}

} // anonymous namespace

int
main(int argc, char** argv)
{
  if (argc < 2)
  {
    std::cerr << "Usage: parser filename\n";
    return 1;
  }

  DumpParser parser;
  Glib::Markup::ParseContext context(parser);

  try
  {
    Glib::ustring contents;
    file_get_contents(argv[1], contents);

    context.parse(contents);
    context.end_parse();
  }
  catch (const Glib::Error& error)
  {
    std::cerr << argv[1] << ": " << error.what() << std::endl;
    return 1;
  }

  return 0;
}
