# win-setemup

## Execution

1. Clone repository / Download all files (& unzip if necessary)
1. Open Admin PowerShell & navigate to containing directory (e.g. `cd ~\Downloads\win-setemup-develop`)
1. Adapt config.yml to your liking (e.g. `Notepad .\config.yml`)
1. Execute setemup.ps1 with the following powershell command:
> :warning: The following command executes the supplied script bypassing your powershell execution policy. It should only be used with scripts you trust. Your execution policy does not change permanently.
```PowerShell
PowerShell.exe -ExecutionPolicy Bypass -File .\setemup.ps1
```
