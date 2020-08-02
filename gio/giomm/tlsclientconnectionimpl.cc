/* Copyright (C) 2020 The giomm Development Team
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

#include <giomm/tlsclientconnectionimpl.h>

namespace Gio
{
TlsClientConnectionImpl::TlsClientConnectionImpl(GTlsConnection* castitem)
: Glib::ObjectBase(nullptr), TlsConnection(castitem)
{}
} /* namespace Gio */

namespace Glib
{

Glib::RefPtr<Gio::TlsClientConnectionImpl> wrap_tls_client_connection_impl(
  GTlsConnection* object, bool take_copy)
{
  using IfaceImpl = Gio::TlsClientConnectionImpl;

  ObjectBase* pCppObject = nullptr;
  if (object)
  {
    pCppObject = ObjectBase::_get_current_wrapper((GObject*)object);

    if (!pCppObject)
      pCppObject = new IfaceImpl(object);

    if (take_copy)
      pCppObject->reference();
  }
  return Glib::make_refptr_for_instance<IfaceImpl>(dynamic_cast<IfaceImpl*>(pCppObject));
}

} /* namespace Glib */
