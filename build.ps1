# python misc/scripts/install_d3d12_sdk_windows.py
scons `
  platform=windows `
  d3d12=yes `
  production=yes `
  debug_symbols=yes `
  -j8 `
#   vsproj=yes
