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
if ($config.reduce_telemetry -eq 'true') {
	Write-Host "reducing telemetry as far as possible for current win license..."
	Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' AllowTelemetry 0
}

$regExplorer = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'

if ($config.file_explorer.unhide_hidden_files -eq 'true') {
	Write-Host "unhiding hidden files..."
	Set-ItemProperty $regExplorer\Advanced Hidden 1
}

if ($config.file_explorer.unhide_file_extensions -eq 'true') {
	Write-Host "unhiding file extensions..."
	Set-ItemProperty $regExplorer\Advanced HideFileExt 0
}

if ($config.file_explorer.unhide_superhidden_files -eq 'true') {
	Write-Host "unhiding superhidden files..."
	Set-ItemProperty $regExplorer\Advanced ShowSuperHidden 1
}

if ($config.file_explorer.unhide_full_path_in_title -eq 'true') {
	Write-Host "unhiding full path in file explorer title bar..."
	Set-ItemProperty $regExplorer\CabinetState FullPath 1
}

Write-Host "restarting file explorer..."
Stop-Process -processname explorer

if ($config.theme.dark_mode -eq 'true') {
	Write-Host "setting dark mode..."
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize SystemUsesLightTheme 0
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize AppsUseLightTheme 0
}

if ($config.theme.transparency_off -eq 'true') {
	Write-Host "turning off transparency..."
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize EnableTransparency 0
}

if ($config.developer_mode -eq 'true') {
	Write-Host "enabling developer mode..."
	Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ AllowAllTrustedApps 1
	Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ AllowDevelopmentWithoutDevLicense 1
} elseif ($config.sideload_apps -eq 'true') {
	Write-Host "enabling sideload apps..."
	Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ AllowAllTrustedApps 1
}

Write-Host "----------------CHOCO-&-APPS---------------"

$testChocoVer = powershell choco -v

if (-not $testChocoVer) {
    Write-Output "detected no choco, installing now..."
	# TODO : checksum check
	Invoke-Expression $webClient.DownloadString('https://chocolatey.org/install.ps1')
} else {
    Write-Output "detected choco version $testChocoVer"
}

foreach ($app in $config.choco_apps) {
	# TODO : correct way to check if remote choco package exists
	$measure = choco search -er $app | Measure-Object -Line
	# chocolatey always outputs its version so minimum one line
	if ($measure.lines -gt 1) {
		Write-Host "installing $app"
		choco install -y $app
	} else {
		Write-Host "!!! $app not found !!!"
		$app | Out-File $DesktopPath\choco_ignored.txt -Append
	}
}

Write-Host "----------------OTHER-STUFF----------------"

if ($config.device_name) {
	$new_device_name = $config.device_name.toString()
	Write-Host "setting device name to $new_device_name ..."
	Rename-Computer -NewName $new_device_name
}

Write-Host "---------------[ ALL-DONE ]----------------"
Write-Host "!!! Check your desktop for important logs !!!"

$confirmation = Read-Host -Prompt "Restart pc? [Y | N]"
if ($confirmation -ieq 'y') {
    Restart-Computer
}

Read-Host -Prompt "Some changes won't take effect until next restart! - [ENTER] to exit"
