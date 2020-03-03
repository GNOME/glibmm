#!/usr/bin/env python3

# External command, intended to be called with custom_target() in meson.build

#                      argv[1]      argv[2]       argv[3]
# compile-schemas.py <schema_dir> <target_dir> <output_file>

import os
import sys
import subprocess
import shutil

schema_dir = sys.argv[1]
target_dir = sys.argv[2]
output_file = sys.argv[3]

# Create the target directory, if it does not exist.
os.makedirs(target_dir, exist_ok=True)

cmd = [
  'glib-compile-schemas',
  '--strict',
  '--targetdir=' + target_dir,
  schema_dir,
]

result = subprocess.run(cmd)
if result.returncode == 0:
  shutil.copy(os.path.join(target_dir, 'gschemas.compiled'), output_file)
sys.exit(result.returncode)
