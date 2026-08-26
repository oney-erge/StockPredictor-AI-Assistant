param(
  [ValidateSet("run", "doctor", "repair", "docker", "stop", "logs")]
  [string]$Action = "run",
  [switch]$NoBrowser
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
. .\scripts\install-utils.ps1
Initialize-Install -RepositoryRoot $PSScriptRoot -ProductName "StockPredictor"
trap { Write-InstallFailure $_; Exit-InstallLock; exit 1 }
$UvVersion = "0.12.5"
$apiUrl = "http://127.0.0.1:8000"
$dashboardUrl = "http://127.0.0.1:8501"
function Resolve-Uv { $cmd=Get-Command uv -ErrorAction SilentlyContinue; foreach ($candidate in @($(if($cmd){$cmd.Source}),"$env:USERPROFILE\.local\bin\uv.exe","$env:USERPROFILE\.cargo\bin\uv.exe")) { if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate } }; return $null }
function Ensure-Uv { $uv=Resolve-Uv; if($uv){return $uv}; $file=Join-Path $env:TEMP "stockpredictor-uv-$UvVersion.ps1"; try { Save-InstallDownload -Url "https://astral.sh/uv/$UvVersion/install.ps1" -Destination $file -Label "uv download"; & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $file } finally { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue }; $uv=Resolve-Uv; if(-not $uv){throw "uv installed but could not be located."}; return $uv }
function Test-Url([string]$Url) { try { Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2 | Out-Null; return $true } catch { return $false } }
function Wait-Url([string]$Url) { for($i=0;$i -lt 120;$i++){if(Test-Url $Url){return $true};Start-Sleep -Milliseconds 500};return $false }
function Docker-Running { if(-not(Get-Command docker -ErrorAction SilentlyContinue)){return $false}; docker info *> $null; if($LASTEXITCODE -ne 0){return $false}; return [bool](docker compose ps --quiet 2>$null) }

if($Action -eq "docker") { if(-not(Get-Command docker -ErrorAction SilentlyContinue)){throw "Docker is not installed."}; docker info *> $null; if($LASTEXITCODE -ne 0){throw "Docker is installed but its engine is not running."}; Enter-InstallLock;Assert-InstallFreeSpace -Path $PSScriptRoot -RequiredGB 2; docker compose up --detach --build;if($LASTEXITCODE-ne 0){throw "Docker Compose failed to start StockPredictor."}; if(-not(Wait-Url "$apiUrl/health") -or -not(Wait-Url $dashboardUrl)){docker compose logs;throw "StockPredictor did not become ready."};Complete-Install; if(-not $NoBrowser){Start-Process $dashboardUrl}; Write-Host "StockPredictor is ready at $dashboardUrl" -ForegroundColor Green; exit 0 }
if($Action -eq "stop") { if(Docker-Running){docker compose down;exit $LASTEXITCODE}; & .\scripts\stop-local.ps1;exit $LASTEXITCODE }
if($Action -eq "logs") { if(Docker-Running){docker compose logs --follow;exit $LASTEXITCODE}; Get-Content .\.logs\*.log -Tail 100 -Wait;exit 0 }
$uv=Resolve-Uv
if($Action -eq "doctor"){if(-not$uv){throw "uv is missing. Run .\run.bat once."};& $uv run --frozen --no-sync python -c "import stockpredictor; print('Environment: ready')";Write-Host "API: $(if(Test-Url "$apiUrl/health"){$apiUrl}else{'not running'})";Write-Host "Dashboard: $(if(Test-Url $dashboardUrl){$dashboardUrl}else{'not running'})";exit $LASTEXITCODE}
Enter-InstallLock
Assert-InstallFreeSpace -Path $PSScriptRoot -RequiredGB 2
if(-not$uv){$uv=Ensure-Uv}
$sync=@("sync","--frozen");if($Action -eq "repair"){$sync += "--reinstall"}
Invoke-InstallRetry "dependency synchronization" {$output=& $uv @sync 2>&1;if($LASTEXITCODE-ne 0){throw "uv sync failed: $($output -join [Environment]::NewLine)"};$output|Write-Host}
Complete-Install
& .\scripts\start-local.ps1 -SkipInstall -ReuseExisting -NoBrowser:$NoBrowser
exit $LASTEXITCODE
