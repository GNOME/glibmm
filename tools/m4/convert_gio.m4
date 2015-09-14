_CONV_ENUM(G,AppInfoCreateFlags)
_CONV_ENUM(G,ApplicationFlags)
_CONV_ENUM(G,AskPasswordFlags)
_CONV_ENUM(G,BusType)
_CONV_ENUM(G,ConverterFlags)
_CONV_ENUM(G,ConverterResult)
_CONV_ENUM(G,CredentialsType)
_CONV_ENUM(G,DataStreamByteOrder)
_CONV_ENUM(G,DataStreamNewlineType)
_CONV_ENUM(GDBus,CallFlags)
_CONV_ENUM(GDBus,CapabilityFlags)
_CONV_ENUM(GDBus, InterfaceSkeletonFlags)
_CONV_ENUM(GDBus,MessageFlags)
_CONV_ENUM(GDBus,MessageHeaderField)
_CONV_ENUM(GDBus,MessageType)
_CONV_ENUM(GDBus,ProxyFlags)
_CONV_ENUM(GDBus,SendMessageFlags)
_CONV_ENUM(GDBus,ServerFlags)
_CONV_ENUM(G,DriveStartFlags)
_CONV_ENUM(G,DriveStartFlags)
_CONV_ENUM(G,DriveStartStopType)
_CONV_ENUM(G,EmblemOrigin)
_CONV_ENUM(G,FileAttributeInfoFlags)
_CONV_ENUM(G,FileAttributeStatus)
_CONV_ENUM(G,FileAttributeType)
_CONV_ENUM(G,FileCopyFlags)
_CONV_ENUM(G,FileCreateFlags)
_CONV_ENUM(G,FileMonitorEvent)
_CONV_ENUM(G,FileMonitorFlags)
_CONV_ENUM(G,FileQueryInfoFlags)
_CONV_ENUM(G,FileType)
_CONV_ENUM(G,MountMountFlags)
_CONV_ENUM(G,MountOperationResult)
_CONV_ENUM(G,MountUnmountFlags)
_CONV_ENUM(G,NetworkConnectivity)
_CONV_ENUM(G,NotificationPriority)
_CONV_ENUM(G,OutputStreamSpliceFlags)
_CONV_ENUM(G,PasswordSave)
_CONV_ENUM(G,ResolverRecordType)
_CONV_ENUM(G,ResourceFlags)
_CONV_ENUM(G,ResourceLookupFlags)
_CONV_ENUM(G,SettingsBindFlags)
_CONV_ENUM(G,SocketClientEvent)
_CONV_ENUM(G,SocketFamily)
_CONV_ENUM(G,SocketMsgFlags)
_CONV_ENUM(G,SocketProtocol)
_CONV_ENUM(G,SocketType)
_CONV_ENUM(G,TlsCertificateFlags)
_CONV_ENUM(G,TlsCertificateRequestFlags)
_CONV_ENUM(G,TlsDatabaseVerifyFlags)
_CONV_ENUM(G,TlsDatabaseLookupFlags)
_CONV_ENUM(G,TlsInteractionResult)
_CONV_ENUM(G,TlsPasswordFlags)
_CONV_ENUM(G,TlsRehandshakeMode)
_CONV_ENUM(G,UnixSocketAddressType)
_CONV_ENUM(G,ZlibCompressorFormat)

# Action
_CONVERSION(`GAction*',`Glib::RefPtr<Action>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Action>&',`GAction*',__CONVERT_REFPTR_TO_P)

# ActionGroup
_CONVERSION(`const Glib::RefPtr<ActionGroup>&',`GActionGroup*',__CONVERT_REFPTR_TO_P)

# AppInfo
_CONVERSION(`GAppInfo*',`Glib::RefPtr<AppInfo>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<AppLaunchContext>&',`GAppLaunchContext*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`GAppLaunchContext*',`const Glib::RefPtr<AppLaunchContext>&',Glib::wrap($3))
_CONVERSION(`const Glib::RefPtr<AppInfo>&',`GAppInfo*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`Glib::RefPtr<AppInfo>',`GAppInfo*',__CONVERT_REFPTR_TO_P)
_CONVERSION(`GAppInfo*',`const Glib::RefPtr<AppInfo>&',`Glib::wrap($3)')
_CONVERSION(`const Glib::ListHandle< Glib::RefPtr<Gio::File> >&',`GList*',`$3.data()')

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

# DBusInterface
_CONVERSION(`GDBusInterface*',`Glib::RefPtr<Gio::DBus::Interface>',`Glib::wrap($3)')
_CONVERSION(`Glib::RefPtr<Gio::DBus::Interface>',`GDBusInterface*',`Glib::unwrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::Interface>&',`GDBusInterface*',`Glib::unwrap($3)')

# DBusMethodInvocation
_CONVERSION(`const Glib::RefPtr<MethodInvocation>&',`GDBusMethodInvocation*',`Glib::unwrap($3)')

# DBusObject
_CONVERSION(`GDBusObject*',`Glib::RefPtr<Gio::DBus::Object>',`Glib::wrap($3)')
_CONVERSION(`const Glib::RefPtr<Gio::DBus::Object>&',`GDBusObject*',`Glib::unwrap($3)')
_CONVERSION(`Glib::RefPtr<Gio::DBus::Object>',`GDBusObject*',`Glib::unwrap($3)')

# DBusProxy
_CONVERSION(`GDBusProxy*',`Glib::RefPtr<Proxy>',`Glib::wrap($3)')

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
_CONVERSION(`Glib::TimeVal&', `GTimeVal*', static_cast<$2>(&$3))
_CONVERSION(`const Glib::TimeVal&', `GTimeVal*', const_cast<GTimeVal*>(static_cast<const GTimeVal*>(&$3)))
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
_CONVERSION(`const Glib::RefPtr<MenuItem>&',`GMenuItem*',__CONVERT_CONST_REFPTR_TO_P)

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
_CONVERSION(`const Glib::StringArrayHandle&',`const gchar*-const*',`($3).data()')
_CONVERSION(`const Glib::RefPtr<SettingsBackend>&',`GSettingsBackend*',__CONVERT_REFPTR_TO_P)

_CONVERSION(`GSettingsSchemaKey*',`Glib::RefPtr<SettingsSchemaKey>',`Glib::wrap($3)')
_CONVERSION(`GSettingsSchemaKey*',`Glib::RefPtr<const SettingsSchemaKey>',`Glib::wrap($3)')

_CONVERSION(`GSettingsSchema*',`Glib::RefPtr<SettingsSchema>',`Glib::wrap($3)')
_CONVERSION(`GSettingsSchema*',`Glib::RefPtr<const SettingsSchema>',`Glib::wrap($3)')

_CONVERSION(`GSettingsSchemaSource*',`Glib::RefPtr<SettingsSchemaSource>',`Glib::wrap($3)')


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
