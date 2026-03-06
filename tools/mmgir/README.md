# mmgir

`mmgir` helps to generate *mm-family C++ wrappers for GObject libraries using
GObject introspection.

## How to Use

Find the gir files for the GObject library being wrapped. The default path
for installations is `/usr/share/gir-1.0`.

There's a bug with cairo where GIR files are not installed properly, so you'll
need to download it yourself from
[GitLab](https://gitlab.gnome.org/GNOME/gobject-introspection/-/blob/main/gir/cairo-1.0.gir.in).

```bash
# Example for generating defs for GTK 4
./mmgir --gir Gtk-4.0.gir \
    --additional-gir GObject-2.0.gir \
    --additional-gir Gio-2.0.gir \
    --additional-gir GLib-2.0.gir \
    --additional-gir Gdk-4.0.gir \
    --additional-gir GdkPixbuf-2.0.gir \
    --additional-gir Gsk-4.0.gir \
    --additional-gir Pango-1.0.gir \
    --additional-gir cairo-1.0.gir \
    --enum-defs gtk_enums.defs \
    --function-defs gtk_functions.defs \
    --signal-defs gtk_signals.defs \
    --vfunc-defs gtk_vfuncs.defs
```
