param([string]$FxcPath)
$ErrorActionPreference='Stop'
$binary=Join-Path $PSScriptRoot 'obj/Release/net10.0-windows10.0.19041.0/Roman.cso'
$assembly=(& $FxcPath /dumpbin $binary | Out-String)
if ($LASTEXITCODE -ne 0) { throw 'Shader inspection failed' }
foreach ($semantic in @('SCENE_POSITION','TEXCOORD')) {
    if ($assembly -notmatch $semantic) { throw "Missing $semantic" }
}
$fields=@('mode','amount','radius','density','dispersion','glow','phase','angle','inputBounds')
for($i=0;$i -lt $fields.Length;$i++) {
    $offset=$i*4
    if ($assembly -notmatch "float[1-4]?\s+$($fields[$i]);\s+// Offset:\s+$offset\s") { throw "Invalid layout: $($fields[$i])" }
}
Write-Output 'PASS: shader coordinates and 48-byte constant layout'
