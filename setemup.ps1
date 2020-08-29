if (-not (Get-Module -Name "powershell-yaml")) {
	Write-Host "No powershell-yaml module detected, installing..."
	Install-Module powershell-yaml -Force
}

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$config = ConvertFrom-Yaml (Get-Content .\config.yml | Out-String)

function IsCurrentUserAdmin {
	$user = [Security.Principal.WindowsIdentity]::GetCurrent()
	return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (IsCurrentUserAdmin)) {
	Read-Host -Prompt "Needs to be executed in Admin PowerShell - [ENTER] to exit"
	exit
}

Write-Host (Get-Content -Raw .\welcome.txt)

if (-not $config) {
	Read-Host -Prompt "Parsed config.yml content empty, aborting - [ENTER] to exit"
	exit
}

$confirm = Read-Host -Prompt "Did you set the config.yml values? Start setup? [Y]"
if ($confirm -ne 'y') {
	exit
}
Write-Host "---------------[ LET'S-GO ]----------------"

Write-Host "----------------CHOCO-APPS-----------------"
foreach ($app in $config.choco_apps) {
	# TODO : simpler way to check if remote choco package exists
	$measure = choco search -er $app | Measure-Object -Line
	if ($measure.lines -gt 1) {
		Write-Host "----- installing $app"
		choco install -y $app
	} else {
		Write-Host "!!! $app not found !!!"
		$app | Out-File $DesktopPath\choco_not_installed.txt -Append
	}
}
Write-Host "--------------CHOCO-APPS-DONE--------------"

Write-Host "---------------[ ALL-DONE ]----------------"
Write-Host "!!! Check your desktop for important logs !!!"
Read-Host -Prompt "[ENTER] to exit"
