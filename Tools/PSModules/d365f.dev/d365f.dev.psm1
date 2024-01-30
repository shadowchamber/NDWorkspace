#$scriptRoot = $PSScriptRoot + '\public'

#Get-ChildItem $scriptRoot *.ps1 | ForEach-Object {
#    Import-Module $_.FullName
#}

function Install-ChocoPackage
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [string]$Version = ""
    )

    $ChocoLibPath = "C:\ProgramData\chocolatey\lib"

    $start_time = Get-Date

    if(-not(test-path $ChocoLibPath)) {
        Write-Host "[INFO]Installing $PackageName..." -ForegroundColor Yellow       

        if ($Version -eq "")
        {
            choco install $PackageName --yes
        }
        else
        {
            choco install $PackageName --yes --version $Version
        }
    }
    else {
        Write-Host "[INFO]Upgrading $PackageName..." -ForegroundColor Yellow

        if ($Version -eq "")
        {
            choco upgrade $PackageName --yes
        }
        else
        {
            choco upgrade $PackageName --yes --version $Version
        }
    }

    Write-Host "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}  

function Get-D365FDeploymentFolder
{
    Param(
        [Parameter(Mandatory=$false)]
        [string]$Version = ""
    )

    if (Test-Path -Path K:\AosService)
    {
        $LocalDeploymentFolder = "K:\AosService"
    }
    elseif (Test-Path -Path C:\AosService)
    {
        $LocalDeploymentFolder = "C:\AosService"
    }
    elseif (Test-Path -Path E:\AosService)
    {
        $LocalDeploymentFolder = "E:\AosService"
    }
    else
    {
        throw "Cannot find the AOSService folder in any known location"
    }

    return $LocalDeploymentFolder
}  

function Test-VSRunning
{
    Param(
        [Parameter(Mandatory=$false)]
        [string]$Version = ""
    )

     Write-Host "Test if visual studio running"

    if (Get-Process devenv -ErrorAction SilentlyContinue) 
    {
        throw "Visual studio is running! Please close VS and run the script again."
    }
}

function Import-D365Tools
{
    # Install d365fo.tools if needed
    if (Get-Module -ListAvailable -Name "d365fo.tools") 
    {
        Write-Host "Importing d365fo.tools"
        Import-Module "d365fo.tools"
    }
    else 
    {
        Write-Host "Installing d365fo.tools"
        Install-PackageProvider nuget -Scope CurrentUser -Force -Confirm:$false
        Install-Module d365fo.tools -AllowClobber -SkipPublisherCheck -Force -Confirm:$false
    }
}

function Mount-D365Modules
{
    $LocalDeploymentFolder = Get-D365FDeploymentFolder
    $LocalPackagesFolder = Join-Path $LocalDeploymentFolder "PackagesLocalDirectory"

    Write-Host "Deployment directory: $LocalDeploymentFolder"
    Write-Host "Local packages directory: $LocalPackagesFolder"

    # Get the list of models to junction
    $ModelsToJunction = Get-ChildItem "$PSScriptRoot\..\..\..\Modules\"
    Write-Host "Enabling editing of the following models:" $ModelsToJunction

    foreach ($Model in $ModelsToJunction)
    {
        $LocalModelPath = Join-Path $LocalPackagesFolder $Model
        Write-Host "Local model path $LocalModelPath"
        $RepoPath = Join-Path "$PSScriptRoot\..\..\..\Modules" $Model
        Write-Host "Repo path $RepoPath"

        if (Test-Path $LocalModelPath -PathType Container)
        {
            # Use CMD and rmdir since Powershell Remove-Item tries to recurse subfolders
            Write-Host "Removing existing module $LocalModelPath"
            cmd /c rmdir /s /q $LocalModelPath
        }

        # Create new symbolic links
        Write-Host "Creating new symbolic link for $RepoPath from $LocalModelPath"
        New-Item -ItemType:SymbolicLink -Path:$LocalModelPath -Value:$RepoPath
    }
}
