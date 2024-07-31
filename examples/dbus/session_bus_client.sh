#!/bin/bash

# A script for testing the session_bus_service server.
# Start the server, typically as a background process.
# Run this script.

dbus-send --session --dest="org.glibmm.DBusExample" --print-reply --type=method_call \
  "/org/glibmm/DBus/TestObject" "org.glibmm.DBusExample.Clock.GetTime"

dbus-send --session --dest="org.glibmm.DBusExample" --print-reply --type=method_call \
  "/org/glibmm/DBus/TestObject" "org.glibmm.DBusExample.Clock.SetAlarm" \
  string:"2024-07-30T15:46:48"

# Erroneous method calls
dbus-send --session --dest="org.glibmm.DBusExample" --print-reply --type=method_call \
  "/org/glibmm/DBus/TestObject" "org.glibmm.DBusExample.Clock.GetTime" \
  int32:42

dbus-send --session --dest="org.glibmm.DBusExample" --print-reply --type=method_call \
  "/org/glibmm/DBus/TestObject" "org.glibmm.DBusExample.Clock.SetTime" \
  string:"2024-07-30T15:46:48+02"

dbus-send --session --dest="org.glibmm.DBusExample" --print-reply --type=method_call \
  "/org/glibmm/DBus/TestObject" "org.glibmm.DBusExample.Clock.SetAlarm" \
  string:"2pm today"

