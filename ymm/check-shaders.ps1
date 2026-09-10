param([string]$FxcPath)
$ErrorActionPreference='Stop'
$binary=Join-Path $PSScriptRoot 'obj/Release/net10.0-windows10.0.19041.0/Roman.cso'
$assembly=(& $FxcPath /dumpbin $binary | Out-String)
if ($LASTEXITCODE -ne 0) { throw 'Shader inspection failed' }
foreach ($semantic in @('SCENE_POSITION','TEXCOORD')) {
    if ($assembly -notmatch $semantic) { throw "Missing $semantic" }
}
$fields=@(
    @('mode',0),@('amount',4),@('radius',8),@('density',12),
    @('dispersion',16),@('glow',20),@('phase',24),@('angle',28),
    @('waterAmount',32),@('colorInfluence',36),@('pressure',40),@('viscosity',44),
    @('iterations',48),@('inputBounds',64))
foreach($entry in $fields) {
    if ($assembly -notmatch "float[1-4]?\s+$($entry[0]);\s+// Offset:\s+$($entry[1])\s") { throw "Invalid layout: $($entry[0])" }
}
foreach ($entry in @(@('directions',80),@('waves',336))) {
    if ($assembly -notmatch "float4\s+$($entry[0])\[16\];\s+// Offset:\s+$($entry[1])\s") { throw "Invalid table layout: $($entry[0])" }
}
Write-Output 'PASS: shader coordinates and 592-byte constant layout'

# Report compiler instruction count for future optimization comparisons.
$assembly -split "`n" | Where-Object { $_ -match 'instruction slots used' } | Write-Output
