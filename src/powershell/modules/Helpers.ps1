function Get-Clean-String {
  param (
    [Parameter(Mandatory=$true)] $s,
    [Parameter(Mandatory=$false)] $withUpper,
    [Parameter(Mandatory=$false)] $withLower
  )
  $sanite = ($s -replace '[_:.]', '-')
  $sanite = ($sanite -replace '[^a-zA-Z0-9-]', '')
  if ($withUpper) { return $sanite.toUpper()  }
  if ($withUpper) { return $sanite.toLower()  }
  return $sanite
}

function Test-AzDO {
  $SystemCollectionURI=$env:SYSTEM_COLLECTIONURI
  if ($SystemCollectionURI -eq "" -or $null -eq $SystemCollectionURI)
  {
    Write-Host "It isn't Azure DevOps Execution!"
    [Environment]::SetEnvironmentVariable('LAZDO',$false)
    return
  }
  [Environment]::SetEnvironmentVariable('LAZDO',$true)
  Write-Host "Azure DevOps Execution!"
}

Test-AzDO

function Test-Scoop {
  try {
    scoop help | Out-Null
    return $true
  }
  catch {
    return $false
  }
}
function Add-Scoop {
  try {
    if ( $IsWindows -and -not $? ) {
      Invoke-RestMethod get.scoop.sh -outfile 'install.ps1'
      .\install.ps1 -RunAsAdmin | Out-Null
      Remove-Item -Recurse -Force 'install.ps1'
    }
    return $true
  }
  catch {
    Write-Host "Scoop installation failed.", $_
    Throw "Scoop installation failed.", $_
  }
}

function Test-Conftest {
  try {
    conftest -v
    return $true
  }
  catch {
    return $false
  }
}
function Add-Conftest {
  try {
    if ( $IsLinux ) {
      # install conftest
      if ( $SYSTEM_DEBUG -eq $true ) { Write-Host "Debug: IsLinux: $IsLinux" }
      $pathexec=(Join-Path $PSScriptRoot installers/install_conftest.sh)
      if ( $SYSTEM_DEBUG -eq $true ) { Write-Host "Debug: pathexec: $pathexec" }
      sh $pathexec
      return $?
    }

    if ( $IsWindows ) {
      # install conftest
      if ( $SYSTEM_DEBUG -eq $true ) { Write-Host "Debug: IsLinux: $IsWindows" }
      $isInstalledScoop = Test-Scoop
      if ( $SYSTEM_DEBUG -eq $true ) { Write-Host "Debug: isInstalledScoop: $isInstalledScoop" }
      if ($isInstalledScoop -eq $false) { Add-Scoop }
      scoop install conftest
      return $true
    }
  }
  catch {
    Write-Host "Conftest installation failed.", $_
    Throw "Conftest installation failed.", $_
  }
}
function Get-EnvConfig {
  param (
    [Parameter(Mandatory=$true)] $ROOT_PATH
  )
  $selectedEnv=$null
  $envConfigAll=Get-Content "$ROOT_PATH/src/env.json" | ConvertFrom-Json

  # Faz set do ambiente pelo SYSTEM_TEAMPROJECT do AzDO
  if ( $null -ne $env:SYSTEM_TEAMPROJECT ) {
    $selectedEnv=$env:SYSTEM_TEAMPROJECT
  }

  # Se for nulo acima significa que o Default é DV
  if ($null -eq $selectedEnv -or "TeamProject.Test" -eq $selectedEnv) {
    $selectedEnv = 'TeamProject.DV'
  }

  Write-Host "Selected Environment: $selectedEnv"

  switch ($selectedEnv) {
    $envConfigAll.environments.dv.teamProject.projectName {
      return $envConfigAll.environments.dv
    }
    $envConfigAll.environments.qa.teamProject.projectName {
      return $envConfigAll.environments.qa
    }
    $envConfigAll.environments.pr.teamProject.projectName {
      return $envConfigAll.environments.pr
    }
  }
}