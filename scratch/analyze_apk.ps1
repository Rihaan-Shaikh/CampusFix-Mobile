Add-Type -AssemblyName System.IO.Compression.FileSystem

$apkPath = "build/app/outputs/flutter-apk/app-debug.apk"
$zip = [System.IO.Compression.ZipFile]::OpenRead($apkPath)

Write-Host "Top entries by uncompressed size in $apkPath :"
Write-Host ("{0,-50} {1,15} {2,15}" -f "Entry Name", "Uncompressed MB", "Compressed MB")
Write-Host ("-" * 82)

$top = $zip.Entries | Sort-Object Length -Descending | Select-Object -First 15
foreach ($entry in $top) {
    $uMB = [math]::Round($entry.Length / 1MB, 2)
    $cMB = [math]::Round($entry.CompressedLength / 1MB, 2)
    Write-Host ("{0,-50} {1,15} {2,15}" -f $entry.FullName, $uMB, $cMB)
}

$zip.Dispose()
