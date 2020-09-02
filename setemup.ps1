#Requires -RunAsAdministrator
#Requires -Version 5

if (-not (Get-Module -Name "powershell-yaml")) {
	Write-Host "No powershell-yaml module detected, installing..."
	Install-Module powershell-yaml -Force
}

$webClient = [System.Net.WebClient]::new()
$config = ConvertFrom-Yaml (Get-Content .\config.yml | Out-String)
$DesktopPath = [Environment]::GetFolderPath("Desktop")

Write-Host (Get-Content -Raw .\welcome.txt)

if (-not $config) {
	Read-Host -Prompt "Parsed config.yml content empty, aborting - [ENTER] to exit"
	exit
}

$confirm = Read-Host -Prompt "Did you set the config.yml values? Start setup? [Y | N]"
if ($confirm -ine 'y') {
	exit
}

Write-Host "----------------[ LET'S-GO ]---------------"

Write-Host "---------------WIN-REG-CHANGES-------------"

# reduce telemetry to 0 only works for win10 enterprise/education/iot/server licenses, system doesn't mention it though
Write-Host "reducing telemetry as far as possible for current win license..."
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' AllowTelemetry 0

$regExplorer = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'

Write-Host "unhiding hidden files..."
Set-ItemProperty $regExplorer\Advanced Hidden 1

Write-Host "unhiding file extensions..."
Set-ItemProperty $regExplorer\Advanced HideFileExt 0

Write-Host "unhiding superhidden files..."
Set-ItemProperty $regExplorer\Advanced ShowSuperHidden 1

Write-Host "unhiding full path in file explorer title bar..."
Set-ItemProperty $regExplorer\CabinetState FullPath 1

Write-Host "restarting file explorer..."
Stop-Process -processname explorer

Write-Host "----------------CHOCO-&-APPS---------------"

$testChocoVer = powershell choco -v

if (-not $testChocoVer) {
    Write-Output "detected no choco, installing now..."
	Invoke-Expression $webClient.DownloadString('https://chocolatey.org/install.ps1')
} else {
    Write-Output "detected choco version $testChocoVer"
}

foreach ($app in $config.choco_apps) {
	# TODO : simpler way to check if remote choco package exists
	$measure = choco search -er $app | Measure-Object -Line
	if ($measure.lines -gt 1) {
		Write-Host "installing $app"
		choco install -y $app
	} else {
		Write-Host "!!! $app not found !!!"
		$app | Out-File $DesktopPath\choco_ignored.txt -Append
	}
}

Write-Host "----------------OTHER-STUFF----------------"

$temp = $config.device_name # TODO : simpler way
if ($temp) {
	Write-Host "setting device name to $temp ..."
	Rename-Computer -NewName $temp
} else {
	Write-Host "no device name specified, skipping..."
}

Write-Host "---------------[ ALL-DONE ]----------------"
Write-Host "!!! Check your desktop for important logs !!!"

$confirmation = Read-Host -Prompt "Restart pc? [Y | N]"
if ($confirmation -ieq 'y') {
    Restart-Computer
}

Read-Host -Prompt "Some changes won't take effect until next restart! - [ENTER] to exit"
