if (-not (Get-Module -Name "powershell-yaml")) {
	Write-Host "No powershell-yaml module detected, installing..."
    Install-Module powershell-yaml -Force
}

function IsCurrentUserAdmin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (IsCurrentUserAdmin)) {
	Read-Host -Prompt "Needs to be executed in Admin PowerShell - [ENTER] to exit"
	exit
}

$config = ConvertFrom-Yaml (Get-Content .\config.yml | Out-String)
if (-not $config) {
	Read-Host -Prompt "Parsed config.yml content empty, aborting - [ENTER] to exit"
	exit
}

Write-Host "---------- ALL DONE ----------"
Read-Host -Prompt "[ENTER] to exit"
