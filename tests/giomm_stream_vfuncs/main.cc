/* Copyright (C) 2016 The giomm Development Team
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
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <giomm.h>
#include <iostream>
#include <string>
#include <cstdlib>

// A simple custom stream that base64 encodes data.
// Do not copy it to your code, because it's very slow.
class Base64OutputStream : public Gio::FilterOutputStream
{
public:
  unsigned get_column_width() const { return column_width; }
  void set_column_width(unsigned cw) { column_width = cw; }
  static Glib::RefPtr<Base64OutputStream> create(const Glib::RefPtr<OutputStream>& base_stream)
  {
    return Glib::make_refptr_for_instance<Base64OutputStream>(new Base64OutputStream(base_stream));
  }

protected:
  explicit Base64OutputStream(const Glib::RefPtr<Gio::OutputStream>& base_stream)
    : Gio::FilterOutputStream(base_stream), column(0), bit_count(0), bit_buffer(0), column_width(72) {}

  gssize write_vfunc(const void* buffer, gsize count, const Glib::RefPtr<Gio::Cancellable>& cancellable) override
  {
    char const *byte = (char const *) buffer;
    for (unsigned i = 0; i < count; ++i, ++byte)
    {
      // kindergarten implementation, because the object is not performance :)
      bit_buffer <<= 8;
      bit_buffer |= (*byte & 0xff);
      bit_count += 8;

      if (bit_count == 24)
      {
        clear_pending(); // TODO why is this necessary to avoid an outstanding op. exception?
        flush(cancellable);
        set_pending();
        bit_count = 0;
      }

      if (cancellable && cancellable->is_cancelled())
        throw Gio::Error(Gio::Error::CANCELLED, "Operation cancelled");
    }
    return count;
  }

  bool flush_vfunc(const Glib::RefPtr<Gio::Cancellable>& cancellable) override
  {
    if (bit_count != 24)
      return true;
    char to_write[5];
    gsize len = 4;

    for (unsigned i=0; i<4; ++i)
    {
      unsigned index = (bit_buffer & (0x3f<<(i*6))) >> (i*6);
      to_write[3-i] = base64_encode_str[index];
    }
    column += 4;
    // Yes, I know this is completely wrong.
    if (column >= column_width)
    {
      column = 0;
      to_write[4] = '\n';
      ++len;
    }

    get_base_stream()->write(&to_write, len, cancellable);

    bit_count = 0;
    bit_buffer = 0;

    return true;
  }

  bool close_vfunc(const Glib::RefPtr<Gio::Cancellable>& cancellable) override
  {
    char to_write[5] = "====";
    //get any last bytes (1 or 2) out of the buffer
    switch (bit_count)
    {
    case 16:
      bit_buffer <<= 2;  //pad to make 18 bits
      to_write[0] = base64_encode_str[(bit_buffer & (0x3f << 12)) >> 12];
      to_write[1] = base64_encode_str[(bit_buffer & (0x3f << 6)) >> 6];
      to_write[2] = base64_encode_str[bit_buffer & 0x3f];
      break;

    case 8:
      bit_buffer <<= 4; //pad to make 12 bits
      to_write[0] = base64_encode_str[(bit_buffer & (0x3f << 6)) >> 6];
      to_write[1] = base64_encode_str[bit_buffer & 0x3f];
      break;
    }

    if (bit_count > 0)
    {
      get_base_stream()->write(&to_write, 5, cancellable);
    }
    else
    {
      // null terminate output
      get_base_stream()->write("", 1, cancellable);
    }
    if (get_close_base_stream())
      get_base_stream()->close(cancellable);

    return true;
  }

private:
  static char const *const base64_encode_str;
  unsigned column;
  unsigned bit_count;
  unsigned bit_buffer;
  unsigned column_width;
};

char const *const Base64OutputStream::base64_encode_str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

int main(int, char**)
{
  Glib::init();
  Gio::init();

  try
  {
    char result[256];
    Glib::RefPtr<Gio::MemoryOutputStream> memory_chunk = Gio::MemoryOutputStream::create(result, 256, nullptr, nullptr);
    Glib::RefPtr<Base64OutputStream> base64 = Base64OutputStream::create(memory_chunk);

    std::string data = "Custom GIO streams are cool!";

    base64->set_close_base_stream(true);
    base64->write(data);
    base64->close();

    const std::string base64_should_be("Q3VzdG9tIEdJTyBzdHJlYW1zIGFyZSBjb29sIQ==");
    std::cout << "Original data:       " << data << std::endl;
    std::cout << "base64-encoded data: " << result << std::endl;
    std::cout << "base64 should be:    " << base64_should_be << std::endl;
    if (base64_should_be != result)
    {
      std::cout << "Not correct!" << std::endl;
      return EXIT_FAILURE;
    }
  }
  catch (const Gio::Error& e)
  {
    std::cout << "Gio error: " << e.what() << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
