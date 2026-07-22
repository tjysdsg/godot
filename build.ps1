# python misc/scripts/install_d3d12_sdk_windows.py
param(
  [switch]$vsproj
)

$vsprojOption = if ($vsproj) { "vsproj=yes" } else { "vsproj=no" }

scons `
  platform=windows `
  d3d12=yes `
  production=yes `
  debug_symbols=yes `
  $vsprojOption `
  -j8 `
