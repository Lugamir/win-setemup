#Requires -RunAsAdministrator
#Requires -Version 5

. "$PSScriptRoot\funclib.ps1"

$confirm = Read-Host -Prompt "Did you set the config.yml values? Start setup? [Y | N]"
if ($confirm -ine 'y') {
	Write-Log -Severity 'Warning' -LogMessage "Config values not set, aborting."
	exit
}

$DesktopPath = [Environment]::GetFolderPath("Desktop")

# --------- get config values ---------

if (-not (Get-Module -Name "powershell-yaml")) {
	Write-Log -LogMessage "No powershell-yaml module detected, installing..."
	Install-Module powershell-yaml -Force
}

$config = ConvertFrom-Yaml (Get-Content .\config.yml | Out-String)

# --------- set logging values ---------

if ($config.logging.silent -eq 'true') {
	$Silent = 'true'
}

if ($config.logging.do_log_file -eq 'true') {
	$DoLogFile = 'true'
}

if ($config.logging.log_path) {
	$LogPath = $config.logging.log_path
}

# --------------------------------------

Write-Log -LogMessage (Get-Content -Raw .\welcome.txt)

if (-not $config) {
	Write-Log -Severity 'Error' -LogMessage "Parsed config.yml content empty, aborting."
	Read-Host -Prompt "[ENTER] to exit"
	exit
}

Write-Log -LogMessage "--------------[ INSTALLATION ]-------------"

Write-Log -LogMessage "---------------WIN-REG-CHANGES-------------"

# reduce telemetry to 0 only works for win10 enterprise/education/iot/server licenses, system doesn't mention it though
if ($config.reduce_telemetry -eq 'true') {
	Write-Log -LogMessage "reducing telemetry as far as possible for current win license..."
	Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' AllowTelemetry 0
}

$regExplorer = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'

if ($config.file_explorer.unhide_hidden_files -eq 'true') {
	Write-Log -LogMessage "unhiding hidden files..."
	Set-ItemProperty $regExplorer\Advanced Hidden 1
}

if ($config.file_explorer.unhide_file_extensions -eq 'true') {
	Write-Log -LogMessage "unhiding file extensions..."
	Set-ItemProperty $regExplorer\Advanced HideFileExt 0
}

if ($config.file_explorer.unhide_superhidden_files -eq 'true') {
	Write-Log -LogMessage "unhiding superhidden files..."
	Set-ItemProperty $regExplorer\Advanced ShowSuperHidden 1
}

if ($config.file_explorer.unhide_full_path_in_title -eq 'true') {
	Write-Log -LogMessage "unhiding full path in file explorer title bar..."
	Set-ItemProperty $regExplorer\CabinetState FullPath 1
}

if ($config.task_bar.search_bar_mode) {
	if ($config.task_bar.search_bar_mode -eq 'hidden') {
		Write-Log -LogMessage "hiding task bar search bar..."
		Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search SearchboxTaskbarMode 0
	} elseif ($config.task_bar.search_bar_mode -eq 'icon') {
		Write-Log -LogMessage "hiding task bar search field..."
		Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search SearchboxTaskbarMode 1
	} elseif ($config.task_bar.search_bar_mode -eq 'full') {
		Write-Log -LogMessage "hiding task bar search field..."
		Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search SearchboxTaskbarMode 2
	}
}

if ($config.task_bar.hide_task_view -eq 'true') {
	Write-Log -LogMessage "hiding task bar task view button..."
	Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced ShowTaskViewButton 0
}

Write-Log -LogMessage "restarting file explorer..."
Stop-Process -processname explorer

if ($config.theme.dark_mode -eq 'true') {
	Write-Log -LogMessage "setting dark mode..."
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize SystemUsesLightTheme 0
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize AppsUseLightTheme 0
}

if ($config.theme.transparency_off -eq 'true') {
	Write-Log -LogMessage "turning off transparency..."
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize EnableTransparency 0
}

if ($config.developer_mode -eq 'true') {
	Write-Log -LogMessage "enabling developer mode..."
	Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ AllowAllTrustedApps 1
	Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ AllowDevelopmentWithoutDevLicense 1
} elseif ($config.sideload_apps -eq 'true') {
	Write-Log -LogMessage "enabling sideload apps..."
	Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ AllowAllTrustedApps 1
}

Write-Log -LogMessage "----------------CHOCO-&-APPS---------------"

$testChocoVer = powershell choco -v

if (-not $testChocoVer) {
	Write-Log -LogMessage "detected no choco, installing now..."
	# TODO : checksum check
	$webClient = [System.Net.WebClient]::new()
	Invoke-Expression $webClient.DownloadString('https://chocolatey.org/install.ps1')
} else {
	Write-Log -LogMessage "detected choco version $testChocoVer"
}

foreach ($app in $config.choco_apps) {
	# TODO : correct way to check if remote choco package exists
	$measure = choco search -er $app | Measure-Object -Line
	# chocolatey always outputs its version so minimum one line
	if ($measure.lines -gt 1) {
		Write-Log -LogMessage "installing $app"
		choco install -y $app
	} else {
		Write-Log -Severity 'Warning' -LogMessage "$app not found, skipping..."
		$app | Out-File $DesktopPath\choco_ignored.txt -Append
	}
}

Write-Log -LogMessage "----------------OTHER-STUFF----------------"

if ($config.device_name) {
	$new_device_name = $config.device_name.toString()
	Write-Log -LogMessage "setting device name to $new_device_name ..."
	Rename-Computer -NewName $new_device_name
}

$wallpaper = $config.wallpaper_full_path
if ($wallpaper) {
	if (Test-Path $wallpaper) {
		Write-Log -LogMessage "setting wallpaper to $wallpaper ..."
		Set-ItemProperty 'HKCU:\Control Panel\Desktop\' WallPaper $wallpaper
	} else {
		Write-Log -Severity 'Warning' -LogMessage "can't read wallpaper path [ $wallpaper ], skipping..."
	}
}

Write-Log -Severity 'Ok' -LogMessage "---------------[ ALL-DONE ]----------------"
Write-Log -Severity 'Warning' -LogMessage "Check your desktop for important logs!"

$confirmation = Read-Host -Prompt "Restart pc? [Y | N]"
if ($confirmation -ieq 'y') {
	Write-Log -LogMessage "restarting pc..."
    Restart-Computer
}

Read-Host -Prompt "Some changes won't take effect until next restart! - [ENTER] to exit"
