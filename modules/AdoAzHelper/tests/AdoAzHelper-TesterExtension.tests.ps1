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

            #Copy ADO-Extenson to ExtesionBinFolderPath 
            $ExtensionPath = Join-Path -Path $PSScriptRoot -ChildPath AdoAzHelper-TesterExtension
            Copy-Item -Path "$ExtensionPath\*" -Destination $ExtesionBinFolderPath -Recurse -ErrorAction Stop

            #Install Dependancies
            Set-Location $ExtesionBinFolderPath
            npm --% install vss-web-extension-sdk --save --loglevel=error
            $PackageDetailsAsJson = tfx --% extension create --json
            $PackageDetails = $PackageDetailsAsJson | ConvertFrom-Json

            #Publish Extension
            Start-NewProcess -FilePath 'C:\ProgramData\NodeJS\tfx.cmd' -Arguments "extension publish --vsix $($PackageDetails.path) --service-url https://marketplace.visualstudio.com --token $PublisherPat --publisher $PublisherId --share-with $AdoOrgToShareTo --no-prompt" -ReturnResult
        }
        finally
        {
            Set-Location c:
        }
    }
}