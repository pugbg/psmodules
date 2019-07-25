describe 'AdoAzHelper-TesterExtension' {
    it "Build and Publish To Marketplace" {
        try
        {
            $PublisherId = 'psmodules-tester'
            $PublisherPat = read-host -Prompt 'Publisher PAT'
            $AdoOrgToShareTo = 'gogbg'

            #Create Temp Folder to build the extension
            $ExtesionBinFolderPath = Join-Path -Path "TestDrive:" -ChildPath 'bin\ADO-Extension'
            if (-not (Test-Path -Path $ExtesionBinFolderPath))
            {
                New-Item -Path $ExtesionBinFolderPath -ItemType Directory -ErrorAction Stop
            }
            Set-Location $ExtesionBinFolderPath

            #Copy ADO-Extenson to ExtesionBinFolderPath 
            $ExtensionPath = Join-Path -Path $PSScriptRoot -ChildPath AdoAzHelper-TesterExtension
            Copy-Item -Path "$ExtensionPath\*" -Destination $ExtesionBinFolderPath -Recurse -ErrorAction Stop

            #Inject Dependant module in ps_modules
            Save-module -Name AdoAzHelper -Path "$ExtesionBinFolderPath\task1\ps_modules"

            #Install Dependancies
            $null = Invoke-Expression -Command 'npm init -y --no-update-notifier' -ErrorAction Stop
            $null = Invoke-Expression -Command "npm install vss-web-extension-sdk --save --loglevel=error" -ErrorAction Stop
            $PackageDetailsAsJson = tfx --% extension create --json
            $PackageDetails = $PackageDetailsAsJson | ConvertFrom-Json

            #Publish Extension
            $null = Invoke-Expression -Command "tfx extension publish --vsix $($PackageDetails.path) --service-url https://marketplace.visualstudio.com --token $PublisherPat --publisher $PublisherId --share-with $AdoOrgToShareTo --no-prompt" -ErrorAction Stop
        }
        finally
        {
            Set-Location c:
        }
    }
}

describe "AahPipelineVariable" {

    $env:System_Culture = 'en'

    context "Set single variable" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $result = [System.Collections.Generic.List[string]]::new()
        Set-AahPipelineVariable -InputObject @{
            Name     = 'Var1'
            isSecret = $false
            isOutput = $true
            Value    = 'Value1'
        } 6> 1 | foreach {
            $result.add($_)
        }

        $result.Count | should -be 1
    }

    context "Set multiple variables" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $result = [System.Collections.Generic.List[string]]::new()
        Set-AahPipelineVariable -InputObject @(
            @{
                Name     = 'Var1'
                isSecret = $false
                isOutput = $true
                Value    = 'Value1'
            },
            @{
                Name     = 'Var2'
                isSecret = $false
                isOutput = $true
                Value    = 'Value2'
            },
            @{
                Name     = 'Var3'
                isSecret = $false
                isOutput = $true
                Value    = 'Value3'
            }
        ) 6> 1 | foreach {
            $result.add($_)
        }

        $result.Count | should -be 3
    }
}