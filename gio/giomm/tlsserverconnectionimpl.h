#ifndef _GIOMM_TLSSERVERCONNECTIONIMPL_H
#define _GIOMM_TLSSERVERCONNECTIONIMPL_H

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

#include <giommconfig.h>
#include <giomm/tlsserverconnection.h>
#include <giomm/tlsconnection.h>

namespace Gio
{

/** %Gio::TlsServerConnectionImpl is a Gio::TlsConnection that implements
 * the Gio::TlsServerConnection interface.
 *
 * The GTlsServerConnection interface can be implemented by C classes that
 * derive from GTlsConnection. No public GLib class implements GTlsServerConnection.
 * Some GLib functions, such as g_tls_server_connection_new(), return an object
 * of a class which is derived from GTlsConnection and implements GTlsServerConnection.
 * Since that C class is not public, it's not wrapped in a C++ class.
 * A C object of such a class can be wrapped in a %Gio::TlsServerConnectionImpl object.
 * %Gio::TlsServerConnectionImpl does not directly correspond to any GLib class.
 *
 * This class is intended only for wrapping C objects returned from GLib functions.
 *
 * @newin{2,66}
 */
class GIOMM_API TlsServerConnectionImpl : public TlsServerConnection, public TlsConnection
{
private:
  // noncopyable
  TlsServerConnectionImpl(const TlsServerConnectionImpl&) = delete;
  TlsServerConnectionImpl& operator=(const TlsServerConnectionImpl&) = delete;

  friend class TlsConnection_Class;

protected:
  explicit TlsServerConnectionImpl(GTlsConnection* castitem);

public:
  TlsServerConnectionImpl(TlsServerConnectionImpl&& src) noexcept;
  TlsServerConnectionImpl& operator=(TlsServerConnectionImpl&& src) noexcept;

  ~TlsServerConnectionImpl() noexcept override;
};

} // namespace Gio

#endif /* _GIOMM_TLSSERVERCONNECTIONIMPL_H */
