<#
.SYNOPSIS
  Pulls a dietician's current first-consultation form template
  (GET /api/dietician/consultation-form) and prints / saves it as JSON.

.DESCRIPTION
  Logs in with email + password against the same backend a build talks to
  (API_BASE_URL from config/{dev,prod,local}.json, same file the Flutter app
  uses via --dart-define-from-file), then fetches the consultation-form
  template for that account.

  Credentials, in priority order:
    -Email / -Password parameters
    $env:DW_EMAIL / $env:DW_PASSWORD
    interactive prompt (password is read as a secure string)

.EXAMPLE
  .\scripts\pull-consultation-form.ps1 -Env dev
      # prompts for credentials, prints the form JSON to the console

.EXAMPLE
  .\scripts\pull-consultation-form.ps1 -Env prod -Email me@x.com -Out form.json
      # saves the full response to form.json

.EXAMPLE
  $env:DW_EMAIL='me@x.com'; $env:DW_PASSWORD='...'; .\scripts\pull-consultation-form.ps1
#>
[CmdletBinding()]
param(
  [ValidateSet('dev', 'prod', 'local')]
  [string]$Env = 'dev',

  [string]$Email,
  [string]$Password,

  # Where to write the JSON. Omit to print to stdout.
  [string]$Out,

  # Emit only the fields array (data.fields) instead of the whole response.
  [switch]$FieldsOnly,

  # Override the base URL entirely (skips reading config/*.json).
  [string]$BaseUrl
)

$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 defaults to TLS 1.0/1.1 for some stacks.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$repoRoot = Split-Path -Parent $PSScriptRoot

# ── Resolve API base URL ─────────────────────────────────────────────────
if (-not $BaseUrl) {
  $configPath = Join-Path $repoRoot "config\$Env.json"
  if (-not (Test-Path $configPath)) {
    throw "Config not found: $configPath"
  }
  $config = Get-Content $configPath -Raw | ConvertFrom-Json
  $BaseUrl = $config.API_BASE_URL
}
if (-not $BaseUrl) { throw "Could not determine API_BASE_URL." }
$apiRoot = "$($BaseUrl.TrimEnd('/'))/api/dietician"
Write-Host "Backend: $apiRoot" -ForegroundColor Cyan

# ── Resolve credentials ──────────────────────────────────────────────────
if (-not $Email)    { $Email = $env:DW_EMAIL }
if (-not $Password) { $Password = $env:DW_PASSWORD }
if (-not $Email) {
  $Email = Read-Host "Dietician email"
}
if (-not $Password) {
  $secure = Read-Host "Password" -AsSecureString
  $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  )
}

# ── Log in ───────────────────────────────────────────────────────────────
Write-Host "Logging in as $Email ..." -ForegroundColor Cyan
try {
  $loginResp = Invoke-RestMethod -Method Post -Uri "$apiRoot/auth/login" `
    -ContentType 'application/json' `
    -Body (@{ email = $Email; password = $Password } | ConvertTo-Json)
}
catch {
  throw "Login request failed: $($_.Exception.Message)"
}
if (-not $loginResp.success -or -not $loginResp.data.accessToken) {
  throw "Login failed: $($loginResp.message)"
}
$token = $loginResp.data.accessToken

# ── Fetch the consultation-form template ─────────────────────────────────
Write-Host "Fetching consultation form ..." -ForegroundColor Cyan
$formResp = Invoke-RestMethod -Method Get -Uri "$apiRoot/consultation-form" `
  -Headers @{ Authorization = "Bearer $token" }

if (-not $formResp.success) {
  throw "Fetch failed: $($formResp.message)"
}

$fieldCount = @($formResp.data.fields).Count
Write-Host "OK - $fieldCount field(s)." -ForegroundColor Green

# ── Output ───────────────────────────────────────────────────────────────
$payload = if ($FieldsOnly) { $formResp.data.fields } else { $formResp }
$json = $payload | ConvertTo-Json -Depth 20

if ($Out) {
  $outPath = if ([IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location) $Out }
  $json | Out-File -FilePath $outPath -Encoding utf8
  Write-Host "Wrote $outPath" -ForegroundColor Green
}
else {
  $json
}
