param(
  [switch]$Build
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSNativeCommandUseErrorActionPreference = $true
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-VerifyStep {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [scriptblock]$Command
  )

  Write-Host ""
  Write-Host "==> $Name"
  & $Command

  if ($LASTEXITCODE -ne 0) {
    throw "Verification step failed: $Name"
  }
}

Invoke-VerifyStep "node --check main.js" {
  node --check main.js
}

Invoke-VerifyStep "node --check preload.js" {
  node --check preload.js
}

Invoke-VerifyStep "node --check renderer/app.js" {
  node --check renderer/app.js
}

Invoke-VerifyStep "npm ls --depth=0" {
  npm ls --depth=0
}

Invoke-VerifyStep "npm audit --audit-level=moderate" {
  npm audit --audit-level=moderate
}

if ($Build) {
  Invoke-VerifyStep "npm run build" {
    npm run build
  }
}

Write-Host ""
Write-Host "Verification completed successfully."
