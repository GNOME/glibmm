# mmgir

`mmgir` helps to generate *mm-family C++ wrappers for GObject libraries using
GObject introspection.

## How to Use

Find the gir files for the GObject library being wrapped. The default path
for installations is `/usr/share/gir-1.0`.

Some gir files may be missing from your local installation. If so, consider
obtaining them from [GitLab](https://gitlab.gnome.org/GNOME/gobject-introspection/-/tree/main/gir).

```bash
# Example for generating defs for GTK 4
#
# cairo-1.0.gir and freetype2-2.0.gir were obtained from the official GitLab.
./mmgir --gir Gtk-4.0.gir \
    --additional-gir cairo-1.0.gir \
    --additional-gir freetype2-2.0.gir \
    --gir-search-dir /usr/share/gir-1.0/ \
    --enum-defs gtk_enums.defs \
    --function-defs gtk_functions.defs \
    --signal-defs gtk_signals.defs \
    --vfunc-defs gtk_vfuncs.defs
```
