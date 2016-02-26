#ifndef _GIOMM_H
#define _GIOMM_H

/*
 * Copyright (C) 2007 The giomm Development Team
 *
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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <glibmm.h>

#include <giomm/action.h>
#include <giomm/actiongroup.h>
#include <giomm/actionmap.h>
#include <giomm/appinfo.h>
#include <giomm/applaunchcontext.h>
#include <giomm/application.h>
#include <giomm/applicationcommandline.h>
#include <giomm/asyncinitable.h>
#include <giomm/asyncresult.h>
#include <giomm/bufferedinputstream.h>
#include <giomm/bufferedoutputstream.h>
#include <giomm/cancellable.h>
#include <giomm/charsetconverter.h>
#include <giomm/contenttype.h>
#include <giomm/converter.h>
#include <giomm/converterinputstream.h>
#include <giomm/converteroutputstream.h>
#include <giomm/credentials.h>
#include <giomm/datainputstream.h>
#include <giomm/dataoutputstream.h>
#include <giomm/dbusactiongroup.h>
#include <giomm/dbusaddress.h>
#include <giomm/dbusauthobserver.h>
#include <giomm/dbusconnection.h>
#include <giomm/dbuserror.h>
#include <giomm/dbuserrorutils.h>
#include <giomm/dbusinterface.h>
#include <giomm/dbusinterfacevtable.h>
#include <giomm/dbusintrospection.h>
#include <giomm/dbusmenumodel.h>
#include <giomm/dbusmessage.h>
#include <giomm/dbusmethodinvocation.h>
#include <giomm/dbusobject.h>
#include <giomm/dbusownname.h>
#include <giomm/dbusproxy.h>
#include <giomm/dbusserver.h>
#include <giomm/dbussubtreevtable.h>
#include <giomm/dbusutils.h>
#include <giomm/dbuswatchname.h>
#ifndef G_OS_WIN32
#include <giomm/desktopappinfo.h>
#endif
#include <giomm/drive.h>
#include <giomm/emblem.h>
#include <giomm/emblemedicon.h>
#include <giomm/enums.h>
#include <giomm/error.h>
#include <giomm/file.h>
#include <giomm/fileattributeinfo.h>
#include <giomm/fileattributeinfolist.h>
#include <giomm/fileenumerator.h>
#include <giomm/fileicon.h>
#include <giomm/fileinfo.h>
#include <giomm/fileinputstream.h>
#include <giomm/fileiostream.h>
#include <giomm/filemonitor.h>
#include <giomm/filenamecompleter.h>
#include <giomm/fileoutputstream.h>
#include <giomm/filterinputstream.h>
#include <giomm/filteroutputstream.h>
#include <giomm/icon.h>
#include <giomm/inetaddress.h>
#include <giomm/inetsocketaddress.h>
#include <giomm/init.h>
#include <giomm/initable.h>
#include <giomm/inputstream.h>
#include <giomm/iostream.h>
#include <giomm/loadableicon.h>
#include <giomm/memoryinputstream.h>
#include <giomm/memoryoutputstream.h>
#include <giomm/menu.h>
#include <giomm/menuattributeiter.h>
#include <giomm/menuitem.h>
#include <giomm/menulinkiter.h>
#include <giomm/menumodel.h>
#include <giomm/mount.h>
#include <giomm/mountoperation.h>
#include <giomm/networkaddress.h>
#include <giomm/networkservice.h>
#include <giomm/notification.h>
#include <giomm/outputstream.h>
#include <giomm/permission.h>
#include <giomm/pollableinputstream.h>
#include <giomm/pollableoutputstream.h>
#include <giomm/proxy.h>
#include <giomm/proxyaddress.h>
#include <giomm/proxyresolver.h>
#include <giomm/remoteactiongroup.h>
#include <giomm/resolver.h>
#include <giomm/resource.h>
#include <giomm/seekable.h>
#include <giomm/settings.h>
#include <giomm/settingsschema.h>
#include <giomm/settingsschemakey.h>
#include <giomm/simpleaction.h>
#include <giomm/simpleactiongroup.h>
#include <giomm/simpleiostream.h>
#include <giomm/simplepermission.h>
#include <giomm/socket.h>
#include <giomm/socketaddress.h>
#include <giomm/socketaddressenumerator.h>
#include <giomm/socketclient.h>
#include <giomm/socketconnectable.h>
#include <giomm/socketconnection.h>
#include <giomm/socketcontrolmessage.h>
#include <giomm/socketlistener.h>
#include <giomm/socketservice.h>
#include <giomm/socketsource.h>
#include <giomm/srvtarget.h>
#include <giomm/tcpconnection.h>
#include <giomm/tcpwrapperconnection.h>
#include <giomm/themedicon.h>
#include <giomm/threadedsocketservice.h>
#include <giomm/tlscertificate.h>
#include <giomm/tlsclientconnection.h>
#include <giomm/tlsconnection.h>
#include <giomm/tlsdatabase.h>
#include <giomm/tlsinteraction.h>
#include <giomm/tlspassword.h>
#include <giomm/tlsserverconnection.h>
#ifndef G_OS_WIN32
#include <giomm/unixconnection.h>
#include <giomm/unixcredentialsmessage.h>
#include <giomm/unixfdlist.h>
#include <giomm/unixfdmessage.h>
#include <giomm/unixinputstream.h>
#include <giomm/unixoutputstream.h>
#include <giomm/unixsocketaddress.h>
#endif
#include <giomm/volume.h>
#include <giomm/volumemonitor.h>
#include <giomm/zlibcompressor.h>
#include <giomm/zlibdecompressor.h>

#endif /* #ifndef _GIOMM_H */
