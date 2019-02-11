function Get-TVID {

    param(
        [string] $Hostname,
        [switch] $Copy
        )



    #Suppresses errors
    $ErrorActionPreference = "SilentlyContinue"

    #Variables
    $Target = $Hostname
    If (!$Target) {$Target = $env:COMPUTERNAME}

    #Enable Remote Registry Service
    Set-Service -Name "RemoteRegistry" -ComputerName $Target -StartupType Automatic
    start-sleep -s 3

    #Start Remote Registry Service
    If ($Target -ne $env:COMPUTERNAME) {
        $Service = Get-Service -Name "RemoteRegistry" -ComputerName $Target
        $Service.Start()
        Start-sleep -s 3
    }

    #Attempts to pull clientID value from remote registry and display it if successful
    $RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Target)
    $RegKey= $RegCon.OpenSubKey("SOFTWARE\\WOW6432Node\\TeamViewer")
    $ClientID = $RegKey.GetValue("clientID")


    #If previous attempt was unsuccessful, attempts the same from a different location
    If (!$clientid) {
        $RegKey= $RegCon.OpenSubKey("SOFTWARE\\WOW6432Node\\TeamViewer\Version9")
        $ClientID = $RegKey.GetValue("clientID")
    }


    #If previous attempt was unsuccessful, attempts the same from a different location
    If (!$clientid) {
        $RegKey= $RegCon.OpenSubKey("SOFTWARE\\TeamViewer")
        $ClientID = $RegKey.GetValue("clientID")
    }


    #Stop Remote Registry service
    If ($Target -ne $env:COMPUTERNAME) {
        $Service.Stop()
    }


    #Display results
    Write-Host
    If (!$clientid) {Write-Host "ERROR: Unable to retrieve clientID value for $Target via remote registry!" -ForegroundColor Red}
    Else {Write-Host "TeamViewer client ID for $Target is $Clientid." -ForegroundColor Yellow }
    Write-Host


    #Copy to clipboard
    If ($copy -and $ClientID) {$ClientID | clip
    "$Target ID IS $ClientID" | Out-File -append -filepath C:\test.txt  }

    
}