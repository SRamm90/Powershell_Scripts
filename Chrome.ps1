$CBookmarksPath = "C:\Users\$env:UserName\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
$CBmTest = Test-Path $CBookmarksPath
$Desktop = "C:\users\$env:UserName\desktop\BookMarks"


IF ($CBmTest -eq 'true') {
Move-Item -Path $CBookmarksPath -Destination $Desktop} 
else {
Write-Output "Bookmarks Path not valid or Chrome not installed"
exit}
Start-Sleep -s 2
Remove-item -path "C:\Users\$env:UserName\AppData\Local\Google\Chrome\User Data\Default\*" -recurse -force 
Start-Sleep -s 2
Start-Process chrome.exe
Start-Sleep -s 15
Stop-Process -name "chrome"
Start-Sleep -s 2
Move-Item -force -Path "C:\users\$env:UserName\desktop\Temp-BookMarks\Bookmarks" -Destination "C:\Users\$env:UserName\AppData\Local\Google\Chrome\User Data\Default\"
Start-Sleep -s 2
Start-Process chrome.exe