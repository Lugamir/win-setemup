function IsCurrentUserAdmin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (IsCurrentUserAdmin)) {
	Read-Host -Prompt "Needs to be executed in Admin PowerShell - [ENTER] to exit"
	exit
}

Write-Host "---------- ALL DONE ----------"
Read-Host -Prompt "[ENTER] to exit"
