# mmgir

`mmgir` helps to generate *mm-family C++ wrappers for GObject libraries using
GObject introspection.

## How to Use

Find the gir files for the GObject library being wrapped. The default path
for installations is `/usr/share/gir-1.0`.

```bash
# Example for generating defs for GTK 3
./mmgir --gir /path/to/Gtk-3.0.gir \
    --enum-defs gtk_enums.defs \
    --function-defs gtk_functions.defs \
    --signal-defs gtk_signals.defs \
    --vfunc-defs ../gtk_vfuncs.defs
```
