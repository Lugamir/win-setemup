#Requires -Version 5

Function Write-Log {
    param (
        [Parameter(Mandatory)] [string]$LogMessage,
        [ValidateSet('Ok','Info','Warning','Error')] [string]$Severity = 'Info'
    )

    $LogMessage = "$(Get-Date -Format G); $Severity; $LogMessage"

    if (-not $NoLog) {
        if (-not $LogPath) {
            $LogPath = "$PSScriptRoot\setemup.log" # default log path
        }
        $LogMessage | Out-File -FilePath $LogPath -Append
    }

    $Color = ""
    switch ($Severity) {
        'Ok' { $Color = "Green" }
        'Warning' { $Color = "Yellow" }
        'Error' { $Color = "Red" }
        default { $Color = "White" }
    }

    if ($Silent -ne 'true') {
        Write-Host -ForegroundColor $Color $LogMessage
    }
}