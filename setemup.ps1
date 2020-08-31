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
if ($confirm -ne 'y') {
	exit
}
Write-Host "---------------[ LET'S-GO ]----------------"

Write-Host "---------------WIN-TELEMETRY---------------"
# reduce telemetry only works for win10 enterprise/education/iot/server licenses
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' 'AllowTelemetry' '0'
Write-Host "------------WIN-TELEMETRY-DONE-------------"

Write-Host "---------------CHOCO-&-APPS----------------"
$testChocoVer = powershell choco -v
if (-not $testChocoVer) {
    Write-Output "detected no choco, installing now..."
	iex $webClient.DownloadString('https://chocolatey.org/install.ps1')
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
Write-Host "--------------CHOCO-APPS-DONE--------------"

Write-Host "----------------DEVICE-NAME----------------"
$temp = $config.device_name # TODO : simpler way
if ($temp) {
	Write-Host "setting device name to $temp ..."
	Rename-Computer -NewName $temp
} else {
	Write-Host "no device name specified, skipping..."
}
Write-Host "-------------DEVICE-NAME-DONE--------------"

Write-Host "---------------[ ALL-DONE ]----------------"
Write-Host "!!! Check your desktop for important logs !!!"

$confirmation = Read-Host -Prompt "Restart pc? [Y | N]"
if ($confirmation -eq 'y') {
    Restart-Computer
}

Read-Host -Prompt "[ENTER] to exit"
