[CmdletBinding()]
param(
    [string]$OutputPath = "C:\IR_Triage",
    [int]$MaxEvents = 200
)

$ErrorActionPreference = "Continue"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Not running as Administrator. Some event logs, processes, or network details may be incomplete."
}

$computerName = $env:COMPUTERNAME
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$runFolder = Join-Path -Path $OutputPath -ChildPath "${computerName}_${timestamp}"
New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

function Save-Artifact {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    $filePath = Join-Path -Path $runFolder -ChildPath "$Name.txt"
    try {
        & $Action | Out-String -Width 4096 | Out-File -FilePath $filePath -Encoding UTF8
    }
    catch {
        "Error collecting ${Name}: $($_.Exception.Message)" | Out-File -FilePath $filePath -Encoding UTF8
    }
}

Save-Artifact "01_system_info" { Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, OsArchitecture, WindowsBuildLabEx, CsBootupState, TimeZone }
Save-Artifact "02_logged_in_users" { quser 2>&1 }
Save-Artifact "03_processes" { Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId, Name, ExecutablePath, CommandLine | Sort-Object ProcessId }
Save-Artifact "04_network_connections" { Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess }
Save-Artifact "05_listening_ports" { Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess }
Save-Artifact "06_dns_cache" { Get-DnsClientCache | Select-Object Entry, RecordName, RecordType, Status, TimeToLive, Data }
Save-Artifact "07_services_running" { Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object Name, DisplayName, StartType }
Save-Artifact "08_scheduled_tasks" { Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' } | Select-Object TaskPath, TaskName, State }

foreach ($logName in @("System", "Application", "Security")) {
    Save-Artifact "09_eventlog_${logName}" {
        Get-WinEvent -LogName $logName -MaxEvents $MaxEvents | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
    }
}

$zipPath = "$runFolder.zip"
Compress-Archive -Path "$runFolder\*" -DestinationPath $zipPath -Force

if (Test-Path $zipPath) {
    $hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
    "$hash  $(Split-Path -Leaf $zipPath)" | Out-File -FilePath "$zipPath.sha256" -Encoding ASCII
    Write-Host "[OK] Triage bundle created: $zipPath" -ForegroundColor Green
    Write-Host "[OK] SHA-256: $hash" -ForegroundColor Green
}
