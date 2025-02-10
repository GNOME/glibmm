dnl
dnl Gio C names have prefix 'G' or 'GDBus' but C++ namespace Gio ot Gio::DBus
dnl
# _CONV_GIO_ENUM(enum_name[, C_enum_name])
# Specify C_enum_name, if it's not the concatenation of G+enum_name.
define(`_CONV_GIO_ENUM',`dnl
_CONV_ENUM(`Gio',`$1',`m4_ifelse(`$2',,`G$1',`$2')')
')dnl

# _CONV_GIO_DBUS_ENUM(enum_name[, C_enum_name])
# Specify C_enum_name, if it's not the concatenation of GDBus+enum_name.
define(`_CONV_GIO_DBUS_ENUM',`dnl
_CONV_ENUM(`Gio::DBus',`$1',`m4_ifelse(`$2',,`GDBus$1',`$2')')
')dnl

# _CONV_GIO_INCLASS_ENUM(class_name, enum_name[, C_enum_name])
# Specify C_enum_name, if it's not the concatenation of G+class_name+enum_name.
define(`_CONV_GIO_INCLASS_ENUM',`dnl
_CONV_INCLASS_ENUM(`Gio',`$1',`$2',`m4_ifelse(`$3',,`G$1$2',`$3')')
')dnl

# _CONV_GIO_DBUS_INCLASS_ENUM(class_name, enum_name[, C_enum_name])
# Specify C_enum_name, if it's not the concatenation of GDBus+class_name+enum_name.
define(`_CONV_GIO_DBUS_INCLASS_ENUM',`dnl
_CONV_INCLASS_ENUM(`Gio::DBus',`$1',`$2',`m4_ifelse(`$3',,`GDBus$1$2',`$3')')
')dnl

_CONV_GIO_INCLASS_ENUM(AppInfo,CreateFlags)
_CONV_GIO_INCLASS_ENUM(Application,Flags)
_CONV_GIO_ENUM(AskPasswordFlags)
_CONV_GIO_ENUM(BusType)
_CONV_GIO_INCLASS_ENUM(Converter,Flags)
_CONV_GIO_INCLASS_ENUM(Converter,Result)
_CONV_GIO_INCLASS_ENUM(Credentials,Type)
_CONV_GIO_ENUM(DataStreamByteOrder)
_CONV_GIO_ENUM(DataStreamNewlineType)
_CONV_GIO_DBUS_ENUM(CallFlags)
_CONV_GIO_DBUS_ENUM(CapabilityFlags)
_CONV_GIO_DBUS_INCLASS_ENUM(InterfaceSkeleton,Flags)
_CONV_GIO_DBUS_INCLASS_ENUM(Message,ByteOrder)
_CONV_GIO_DBUS_ENUM(MessageFlags)
_CONV_GIO_DBUS_ENUM(MessageHeaderField)
_CONV_GIO_DBUS_ENUM(MessageType)
_CONV_GIO_DBUS_INCLASS_ENUM(ObjectManagerClient,Flags)
_CONV_GIO_DBUS_ENUM(ProxyFlags)
_CONV_GIO_DBUS_ENUM(ConnectionFlags)
_CONV_GIO_DBUS_ENUM(SendMessageFlags)
_CONV_GIO_DBUS_INCLASS_ENUM(Server,Flags)
_CONV_GIO_INCLASS_ENUM(Drive,StartFlags)
_CONV_GIO_INCLASS_ENUM(Drive,StartStopType)
_CONV_GIO_INCLASS_ENUM(Emblem,Origin)
_CONV_GIO_INCLASS_ENUM(FileAttributeInfo,Flags)
_CONV_GIO_ENUM(FileAttributeStatus)
_CONV_GIO_ENUM(FileAttributeType)
_CONV_GIO_INCLASS_ENUM(FileCopy,Flags)
_CONV_GIO_INCLASS_ENUM(FileCreate,Flags)
_CONV_GIO_INCLASS_ENUM(FileMonitor,Event)
_CONV_GIO_INCLASS_ENUM(FileMonitor,Flags)
_CONV_GIO_ENUM(FileQueryInfoFlags)
_CONV_GIO_ENUM(FileType)
_CONV_GIO_INCLASS_ENUM(Mount,MountFlags)
_CONV_GIO_ENUM(MountOperationResult)
_CONV_GIO_INCLASS_ENUM(Mount,UnmountFlags)
_CONV_GIO_ENUM(NetworkConnectivity)
_CONV_GIO_INCLASS_ENUM(Notification,Priority)
_CONV_GIO_INCLASS_ENUM(OutputStream,SpliceFlags)
_CONV_GIO_ENUM(PasswordSave)
_CONV_GIO_INCLASS_ENUM(Resolver,NameLookupFlags)
_CONV_GIO_INCLASS_ENUM(Resolver,RecordType)
_CONV_GIO_INCLASS_ENUM(Resource,Flags)
_CONV_GIO_INCLASS_ENUM(Resource,LookupFlags)
_CONV_GIO_INCLASS_ENUM(Settings,BindFlags)
_CONV_GIO_ENUM(SocketClientEvent)
_CONV_GIO_ENUM(SocketFamily)
_CONV_GIO_INCLASS_ENUM(Socket,MsgFlags)
_CONV_GIO_INCLASS_ENUM(Socket,Protocol)
_CONV_GIO_INCLASS_ENUM(Socket,Type)
_CONV_GIO_INCLASS_ENUM(SocketListener,Event)
_CONV_GIO_INCLASS_ENUM(Subprocess,Flags)
_CONV_GIO_ENUM(TlsCertificateFlags)
_CONV_GIO_ENUM(TlsCertificateRequestFlags)
_CONV_GIO_INCLASS_ENUM(TlsDatabase,VerifyFlags)
_CONV_GIO_INCLASS_ENUM(TlsDatabase,LookupFlags)
_CONV_GIO_ENUM(TlsInteractionResult)
_CONV_GIO_INCLASS_ENUM(TlsPassword,Flags)
_CONV_GIO_ENUM(TlsProtocolVersion)
_CONV_GIO_INCLASS_ENUM(UnixSocketAddress,Type)
_CONV_GIO_ENUM(ZlibCompressorFormat)

# Action
_CONVERSION(`GAction*',`Glib::RefPtr<Action>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Action>&',`GAction*',__CONVERT_REFPTR_TO_P)

# ActionGroup
_CONVERSION(`const Glib::RefPtr<ActionGroup>&',`GActionGroup*',__CONVERT_REFPTR_TO_P)

# AppInfo
_CONVERSION(`GAppInfo*',`Glib::RefPtr<AppInfo>',`Glib::wrap($3)')
_CONVERSION(`GAppInfoMonitor*',`Glib::RefPtr<AppInfoMonitor>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<AppLaunchContext>&',`GAppLaunchContext*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`GAppLaunchContext*',`const Glib::RefPtr<AppLaunchContext>&',Glib::wrap($3))
_CONVERSION(`const Glib::RefPtr<AppInfo>&',`GAppInfo*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`Glib::RefPtr<AppInfo>',`GAppInfo*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`GAppInfo*',`const Glib::RefPtr<AppInfo>&',`Glib::wrap($3)')
_CONVERSION(`const std::vector<Glib::RefPtr<Gio::File>>&',`GList*',`Glib::ListHandler<Glib::RefPtr<Gio::File>>::vector_to_list($3).data()')

# Application
_CONVERSION(`GApplication*',`Glib::RefPtr<Application>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Application>&',`GApplication*',__CONVERT_CONST_REFPTR_TO_P)

# ApplicationCommandLine
_CONVERSION(`const Glib::RefPtr<ApplicationCommandLine>&',`GApplicationCommandLine*',__CONVERT_CONST_REFPTR_TO_P)

# AsyncResult
_CONVERSION(`Glib::RefPtr<Glib::Object>',`GObject*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<AsyncResult>&',`GAsyncResult*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`Glib::RefPtr<AsyncResult>&',`GAsyncResult*',__CONVERT_REFPTR_TO_P)

#ByteArray
_CONVERSION(`const Glib::RefPtr<Glib::ByteArray>&',`GByteArray*',`Glib::unwrap($3)')

# Cancellable
_CONVERSION(`const Glib::RefPtr<Cancellable>&',`GCancellable*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<Gio::Cancellable>&',`GCancellable*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`GCancellable*', `Glib::RefPtr<Cancellable>', `Glib::wrap($3)')
_CONVERSION(`GCancellable*', `const Glib::RefPtr<Cancellable>&', `Glib::wrap($3)')

# Converter
_CONVERSION(`const Glib::RefPtr<Converter>&',`GConverter*',`Glib::unwrap($3)')
_CONVERSION(`GConverter*',`Glib::RefPtr<Converter>',`Glib::wrap($3)')

# Credentials
_CONVERSION(`const Glib::RefPtr<Credentials>&',`GCredentials*',__CONVERT_CONST_REFPTR_TO_P_SUN(Gio::Credentials))
_CONVERSION(`const Glib::RefPtr<const Credentials>&',`GCredentials*',__CONVERT_CONST_REFPTR_TO_P_SUN(Gio::Credentials))
_CONVERSION(`GCredentials*',`Glib::RefPtr<Credentials>',`Glib::wrap($3)')
_CONVERSION(`GCredentials*',`Glib::RefPtr<const Credentials>',`Glib::wrap($3)')

# DBusConnection
_CONVERSION(`const Glib::RefPtr<Connection>&',`GDBusConnection*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<const Connection>&',`GDBusConnection*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`GDBusConnection*',`Glib::RefPtr<Connection>',Glib::wrap($3))
_CONVERSION(`GDBusConnection*',`Glib::RefPtr<const Connection>',Glib::wrap($3))
_CONVERSION(`GDBusConnection*',`Glib::RefPtr<DBus::Connection>',Glib::wrap($3))
_CONVERSION(`GDBusConnection*',`Glib::RefPtr<const DBus::Connection>',Glib::wrap($3))

# DBusMessage
_CONVERSION(`const Glib::RefPtr<Message>&',`GDBusMessage*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`GDBusMessage*',`Glib::RefPtr<Message>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<const Message>&',`GDBusMessage*',__CONVERT_CONST_REFPTR_TO_P)

# DBus*Info
_CONVERSION(`GDBusMethodInfo*',`Glib::RefPtr<MethodInfo>',`Glib::wrap($3)')
_CONVERSION(`GDBusSignalInfo*',`Glib::RefPtr<SignalInfo>',`Glib::wrap($3)')
_CONVERSION(`GDBusPropertyInfo*',`Glib::RefPtr<PropertyInfo>',`Glib::wrap($3)')
_CONVERSION(`GDBusNodeInfo*',`Glib::RefPtr<NodeInfo>',`Glib::wrap($3)')
_CONVERSION(`GDBusInterfaceInfo*',`Glib::RefPtr<InterfaceInfo>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<InterfaceInfo>&',`GDBusInterfaceInfo*',`Glib::unwrap($3)')
_CONVERSION(`Glib::RefPtr<InterfaceInfo>',`GDBusInterfaceInfo*',`Glib::unwrap($3)')
_CONVERSION(`GDBusInterfaceInfo*',`const Glib::RefPtr<InterfaceInfo>',`Glib::wrap($3)')

# DBusInterface, DBusInterfaceSkeleton
_CONVERSION(`GDBusInterface*',`Glib::RefPtr<Gio::DBus::Interface>',`Glib::wrap($3)')
_CONVERSION(`Glib::RefPtr<Gio::DBus::Interface>',`GDBusInterface*',`Glib::unwrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::Interface>&',`GDBusInterface*',`Glib::unwrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::InterfaceSkeleton>&',`GDBusInterfaceSkeleton*',`Glib::unwrap($3)')

# DBusMethodInvocation
_CONVERSION(`const Glib::RefPtr<MethodInvocation>&',`GDBusMethodInvocation*',`Glib::unwrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::MethodInvocation>&',`GDBusMethodInvocation*',`Glib::unwrap($3)')

# DBusObject, DBusObjectProxy, DBusObjectSkeleton
_CONVERSION(`GDBusObject*',`Glib::RefPtr<Gio::DBus::Object>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::Object>&',`GDBusObject*',`Glib::unwrap($3)')
_CONVERSION(`Glib::RefPtr<Gio::DBus::Object>',`GDBusObject*',`Glib::unwrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::ObjectProxy>&',`GDBusObjectProxy*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<Gio::DBus::ObjectSkeleton>&',`GDBusObjectSkeleton*',__CONVERT_REFPTR_TO_P)

# DBusProxy
_CONVERSION(`GDBusProxy*',`Glib::RefPtr<Gio::DBus::Proxy>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::Proxy>&',`GDBusProxy*',__CONVERT_REFPTR_TO_P)

# DesktopAppInfo
_CONVERSION(`GDesktopAppInfo*', `Glib::RefPtr<DesktopAppInfo>', `Glib::wrap($3)')

# Drive
_CONVERSION(`GDrive*',`Glib::RefPtr<Drive>',`Glib::wrap($3)')

# File
_CONVERSION(`return-char*',`std::string',`Glib::convert_return_gchar_ptr_to_stdstring($3)')
_CONVERSION(`Glib::RefPtr<File>',`GFile*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<File>&',`GFile*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<const File>&',`GFile*',__CONVERT_CONST_REFPTR_TO_P_SUN(Gio::File))
_CONVERSION(`GFile*',`Glib::RefPtr<File>',`Glib::wrap($3)')
_CONVERSION(`GFile*',`Glib::RefPtr<const File>',`Glib::wrap($3)')

# FileAttribute
_CONVERSION(`GFileAttributeValue*',`FileAttributeValue',`Glib::wrap($3)')
_CONVERSION(`const FileAttributeValue&',`const GFileAttributeValue*',`$3.gobj()')
_CONVERSION(`GFileAttributeInfoList*',`Glib::RefPtr<FileAttributeInfoList>',`Glib::wrap($3)')

# FileAttributeMatcher
_CONVERSION(`GFileAttributeMatcher*',`Glib::RefPtr<FileAttributeMatcher>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<const FileAttributeMatcher>&',`GFileAttributeMatcher*',`const_cast<GFileAttributeMatcher*>(Glib::unwrap($3))')

#FileEnumerator
_CONVERSION(`GFileEnumerator*',`Glib::RefPtr<FileEnumerator>',`Glib::wrap($3)')

# FileInfo
_CONVERSION(`GFileInfo*',`Glib::RefPtr<FileInfo>',`Glib::wrap($3)')
_CONVERSION(`Glib::RefPtr<FileInfo>&',`GFileInfo*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<FileInfo>&',`GFileInfo*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<FileAttributeMatcher>&',`GFileAttributeMatcher*',__CONVERT_CONST_REFPTR_TO_P)

# FileInputStream
_CONVERSION(`GFileInputStream*',`Glib::RefPtr<FileInputStream>',`Glib::wrap($3)')

# FileMonitor
_CONVERSION(`GFileMonitor*',`Glib::RefPtr<FileMonitor>',`Glib::wrap($3)')

# FileOutputStream
_CONVERSION(`GFileOutputStream*',`Glib::RefPtr<FileOutputStream>',`Glib::wrap($3)')

# FilterInputStream
#_CONVERSION(`GFilterInputStream*',`Glib::RefPtr<FilterInputStream>',`Glib::wrap($3)')

_CONVERSION(`GFileIOStream*',`Glib::RefPtr<FileIOStream>',`Glib::wrap($3)')

# Icon
_CONVERSION(`GIcon*',`Glib::RefPtr<Icon>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Icon>&',`GIcon*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`Glib::RefPtr<Icon>',`GIcon*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`Glib::RefPtr<const Icon>',`GIcon*',__CONVERT_CONST_REFPTR_TO_P)

# Emblem
_CONVERSION(`const Glib::RefPtr<Emblem>&',`GEmblem*',__CONVERT_CONST_REFPTR_TO_P)

# IOStream
_CONVERSION(`GIOStream*',`Glib::RefPtr<Gio::IOStream>',`Glib::wrap($3)')
_CONVERSION(`GIOStream*',`Glib::RefPtr<IOStream>',`Glib::wrap($3)')
_CONVERSION(`GIOStream*',`Glib::RefPtr<const Gio::IOStream>',`Glib::wrap($3)')
_CONVERSION(`GIOStream*',`Glib::RefPtr<const IOStream>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<IOStream>&',`GIOStream*',`Glib::unwrap($3)')
_CONVERSION(`const Glib::RefPtr<const IOStream>&',`GIOStream*',`const_cast<GIOStream*>(Glib::unwrap($3))')

# InetAddress
_CONVERSION(`const Glib::RefPtr<InetAddress>&',`GInetAddress*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<const InetAddress>&',`GInetAddress*',`const_cast<GInetAddress*>(Glib::unwrap($3))')
_CONVERSION(`GInetAddress*',`Glib::RefPtr<InetAddress>',`Glib::wrap($3)')

# InputStream
_CONVERSION(`const Glib::RefPtr<InputStream>&',`GInputStream*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<Gio::InputStream>&',`GInputStream*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`GInputStream*',`Glib::RefPtr<InputStream>',`Glib::wrap($3)')
_CONVERSION(`GInputStream*',`Glib::RefPtr<Gio::InputStream>',`Glib::wrap($3)')

# MenuAttributeIter
_CONVERSION(`GMenuAttributeIter*',`Glib::RefPtr<MenuAttributeIter>',`Glib::wrap($3)')

# MenuLinkIter
_CONVERSION(`GMenuLinkIter*',`Glib::RefPtr<MenuLinkIter>',`Glib::wrap($3)')

# MenuModel
_CONVERSION(`GMenuModel*',`Glib::RefPtr<MenuModel>',`Glib::wrap($3)')
_CONVERSION(`GMenuModel*',`Glib::RefPtr<const MenuModel>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<MenuModel>&',`GMenuModel*',__CONVERT_CONST_REFPTR_TO_P)

# MenuItem
_CONVERSION(`GMenuItem*',`Glib::RefPtr<MenuItem>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<const MenuItem>&',`GMenuItem*',__CONVERT_CONST_REFPTR_TO_P)

# Mount
_CONVERSION(`GMount*',`Glib::RefPtr<Mount>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Mount>&',`GMount*',__CONVERT_CONST_REFPTR_TO_P)

# MountOptions
_CONVERSION(`GPasswordSave',`PasswordSave',`($2)$3')
_CONVERSION(`PasswordSave',`GPasswordSave',`($2)$3')

#MountOperation
#_CONVERSION(`GAskPasswordFlags',`AskPasswordFlags',`($2)$3')

# NetworkMonitor
_CONVERSION(`GNetworkMonitor*',`Glib::RefPtr<NetworkMonitor>',`Glib::wrap($3)')


# Notification
_CONVERSION(`GNotification*',`Glib::RefPtr<Notification>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Notification>&',`GNotification*',__CONVERT_CONST_REFPTR_TO_P)

# OutputStream
_CONVERSION(`GOutputStream*',`Glib::RefPtr<OutputStream>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<OutputStream>&',`GOutputStream*',__CONVERT_CONST_REFPTR_TO_P)

_CONVERSION(`const Glib::RefPtr<ProxyResolver>&',`GProxyResolver*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`GProxyResolver*',`Glib::RefPtr<ProxyResolver>',`Glib::wrap($3)')
_CONVERSION(`GProxy*',`Glib::RefPtr<Proxy>',`Glib::wrap($3)')

_CONVERSION(`const Glib::RefPtr<const ProxyAddress>&',`GProxyAddress*',__CONVERT_CONST_REFPTR_TO_P)

#Resource
_CONVERSION(`GResource*',`Glib::RefPtr<Resource>',`Glib::wrap($3)')

#Settings
_CONVERSION(`GSettings*',`Glib::RefPtr<Settings>',`Glib::wrap($3)')
_CONVERSION(`const std::vector<Glib::ustring>&',`const gchar*-const*',`Glib::ArrayHandler<Glib::ustring>::vector_to_array($3).data()')
_CONVERSION(`const Glib::RefPtr<SettingsBackend>&',`GSettingsBackend*',__CONVERT_REFPTR_TO_P)

_CONVERSION(`GSettingsSchemaKey*',`Glib::RefPtr<SettingsSchemaKey>',`Glib::wrap($3)')
_CONVERSION(`GSettingsSchemaKey*',`Glib::RefPtr<const SettingsSchemaKey>',`Glib::wrap($3)')

_CONVERSION(`GSettingsSchema*',`Glib::RefPtr<SettingsSchema>',`Glib::wrap($3)')
_CONVERSION(`GSettingsSchema*',`Glib::RefPtr<const SettingsSchema>',`Glib::wrap($3)')

_CONVERSION(`GSettingsSchemaSource*',`Glib::RefPtr<SettingsSchemaSource>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<SettingsSchemaSource>&',`GSettingsSchemaSource*',__CONVERT_REFPTR_TO_P)

#Socket
_CONVERSION(`const Glib::RefPtr<Socket>&',`GSocket*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`GSocket*',`Glib::RefPtr<Socket>',`Glib::wrap($3)')

#SocketAddress
_CONVERSION(`GSocketAddress*',`Glib::RefPtr<SocketAddress>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<SocketAddress>&',`GSocketAddress*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`Glib::RefPtr<SocketAddress>&',`GSocketAddress*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`GSocketAddressEnumerator*',`Glib::RefPtr<SocketAddressEnumerator>',`Glib::wrap($3)')

#SocketConnectable
_CONVERSION(`const Glib::RefPtr<SocketConnectable>&',`GSocketConnectable*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<const SocketConnectable>&', `GSocketConnectable*', `const_cast<GSocketConnectable*>(Glib::unwrap($3))')
_CONVERSION(`GSocketConnectable*',`Glib::RefPtr<SocketConnectable>',`Glib::wrap($3)')

#SocketConnection
_CONVERSION(`GSocketConnection*',`Glib::RefPtr<SocketConnection>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<SocketConnection>&',`GSocketConnection*',__CONVERT_CONST_REFPTR_TO_P)

#SocketControlMessage
_CONVERSION(`GSocketControlMessage*',`Glib::RefPtr<SocketControlMessage>',`Glib::wrap($3)')

#Subprocess, SubprocessLauncher
_CONVERSION(`GSubprocess*',`Glib::RefPtr<Subprocess>',`Glib::wrap($3)')
_CONVERSION(`GSubprocessLauncher*',`Glib::RefPtr<SubprocessLauncher>',`Glib::wrap($3)')

#TimeZoneMonitor
_CONVERSION(`GTimeZoneMonitor*',`Glib::RefPtr<TimeZoneMonitor>',`Glib::wrap($3)')

#TlsCertificate
_CONVERSION(`GTlsCertificate*', `Glib::RefPtr<TlsCertificate>', `Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<const TlsCertificate>&', `GTlsCertificate*', `const_cast<GTlsCertificate*>(Glib::unwrap($3))')
_CONVERSION(`const Glib::RefPtr<TlsCertificate>&',`GTlsCertificate*',`Glib::unwrap($3)')

#TlsConnection:
_CONVERSION(`const Glib::RefPtr<TlsConnection>&',`GTlsConnection*',`Glib::unwrap($3)')

#TlsClientConnection:
_CONVERSION(`const Glib::RefPtr<TlsClientConnection>&',`GTlsClientConnection*',__CONVERT_REFPTR_TO_P)

#TlsDatabase
_CONVERSION(`GTlsDatabase*',`Glib::RefPtr<TlsDatabase>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<TlsDatabase>&',`GTlsDatabase*',__CONVERT_REFPTR_TO_P)

#TlsInteraction
_CONVERSION(`const Glib::RefPtr<TlsInteraction>&',`GTlsInteraction*',`Glib::unwrap($3)')
_CONVERSION(`GTlsInteraction*',`Glib::RefPtr<TlsInteraction>',`Glib::wrap($3)')

#TlsPassword
_CONVERSION(`const Glib::RefPtr<TlsPassword>&',`GTlsPassword*',__CONVERT_REFPTR_TO_P)

#UnixFDList
_CONVERSION(`GUnixFDList*',`Glib::RefPtr<UnixFDList>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<UnixFDList>&',`GUnixFDList*',__CONVERT_REFPTR_TO_P)

#Volume
_CONVERSION(`GVolume*',`Glib::RefPtr<Volume>',`Glib::wrap($3)')

# VolumeMonitor
_CONVERSION(`GVolumeMonitor*',`Glib::RefPtr<VolumeMonitor>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Drive>&',`GDrive*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<Mount>&',`GMount*',__CONVERT_CONST_REFPTR_TO_P)
_CONVERSION(`const Glib::RefPtr<Volume>&',`GVolume*',__CONVERT_CONST_REFPTR_TO_P)

#Vfs
_CONVERSION(`GVfs*', `Glib::RefPtr<Vfs>', `Glib::wrap($3)')
