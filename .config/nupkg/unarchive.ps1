# Extract iTextSharp.dll
Rename-Item -Path .\pkg\itextsharp.5.5.13.nupkg -NewName .\pkg\itextsharp.5.5.13.zip
Expand-Archive -Path .\pkg\itextsharp.5.5.13.zip -DestinationPath .\tmp
$tmp = (Get-Item -Path .\tmp\lib\itextsharp.dll)
Move-Item -Path $tmp -Destination .

# Remove tmp directory
Remove-Item -Path .\tmp -Recurse
