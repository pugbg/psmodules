<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 3e268f95-0479-4baf-b95e-44152c6970e5

.AUTHOR gogbg@outlook.com

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#> 

<#
.DESCRIPTION
test script
#>
[cmdletbinding()]
param
()

begin
{
    $ErrorActionPreference = "Stop"

    #Get SolutionRootFolder
    $SolutionRootFolder = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent | Split-Path -Parent

    #Initialize Logging
    $LoggingConfigFilePath = Join-Path -Path $SolutionRootFolder -ChildPath 'src\pipelines\configuration\loggingconfig-pipelinetasks.psd1'
    Register-LhConfiguration -PsdConfigurationFilePath $LoggingConfigFilePath
    
    #Show Debug Information
    if ($env:DebugLevel -eq 1)
    {
        Write-LhEvent -Type Debug -Message "Environment Variables:$([System.Environment]::NewLine)$([System.Environment]::GetEnvironmentVariables() | convertto-json)"
    }

    $ProductsRootFolder = Join-Path -Path $SolutionRootFolder -ChildPath 'src\products'
    $ProductTestResultFolderPath = Join-Path -Path $SolutionRootFolder -ChildPath 'bin\testresults'
    $ProductTestResultFilePath = Join-Path -Path $ProductTestResultFolderPath -ChildPath 'testresults-ProductUnitTests.xml'

    $ProductsLabelRegex = [regex]'^product: (.*)'

    $PipelineContext = $Env:PipelineContext | ConvertFrom-Json -ErrorAction Stop
}

process
{
    #Get Products in Scope
    try
    {
        Write-LhEvent -Type Informational -Message "Get Products in Scope started"

        #Get ProductsManifest
        $ProductsManifest = [System.Collections.Generic.List[object]]::new()
        $ProductManifestPath = Join-Path -Path $SolutionRootFolder -ChildPath $ProductManifestRelPath
        if(-not (Test-Path -Path $ProductManifestPath))
        {
            throw "Unable to resolve product manifest path"
        }
        (Get-Content -Path $ProductManifestPath -raw | ConvertFrom-Json).psobject.properties | foreach {
            $_.Value | Add-Member -MemberType NoteProperty -Name Name -Value $_.Name -ErrorAction Stop
            $ProductsManifest.Add($_.Value)
        }

        if ($PipelineContext.TriggeredBy -eq 'PullRequest')
        {
            $ProductLabel = $PipelineContext.PullRequest.Labels | ForEach-Object { 
                Remove-Variable -Name ProductMatches -ErrorAction SilentlyContinue
                $ProductMatches = $ProductsLabelRegex.Match($_)
                if ($ProductMatches.Success)
                {
                    $ProductMatches.Groups[1].Value
                }
            }
            if ($ProductLabel)
            {
                switch ($ProductLabel)
                {
                    'all' {
                        $ProductsInScope = $ProductsManifest | where-object { $_.Enabled }
                        break
                    }
                    'none' {
                        $ProductsInScope = @()
                        break
                    }
                    default {
                        $ProductsInScope = $ProductsManifest | where-object { $_.Enabled -and ($_.Name -eq $ProductLabel)}
                    }
                }
                
            }
            else
            {
                throw "Missing PR ProductLabel tag"
            }
        }
        else
        {
            $ProductsInScope = $ProductsManifest | Where-Object { $_.Enabled }
        }
        Write-LhEvent -Type Informational -Message "Get Products in Scope in progress. Products in Scope: $($ProductsInScope.Name -join ',')"

        Write-LhEvent -Type Informational -Message "Get Products in Scope completed"
    }
    catch
    {
        throw "Get Products in Scope failed. Details: $_"
    }

    #Execute Products Unit Tests
    try
    {
        Write-LhEvent -Type Informational -Message 'Execute Products Unit Tests started'

        #Get Product Unit Tests In Scope
        $ProductUnitTestsPaths = [System.Collections.Generic.List[string]]::new()
        $ProductsInScope | foreach {
            $p = Join-Path -Path $ProductsRootFolder -ChildPath $_.FolderName | Join-Path -ChildPath $_.UnitTestsRelPath
            $ProductUnitTestsPaths.Add($p)
        }

        if ($ProductUnitTestsPaths.Count -gt 0)
        {
            #Create ProductTestResultFilePath if missing
            if (-not (test-path -Path $ProductTestResultFilePath))
            {
                Write-LhEvent -Type Informational -Message "Execute Products Unit Tests in progress. Create Result Folder"
                $null = New-Item -Path $ProductTestResultFolderPath -ItemType Directory -ErrorAction Stop
            }

            Invoke-Pester -OutputFormat NUnitXml -PassThru -OutputFile $ProductTestResultFilePath -Script $ProductUnitTestsPaths -Show Failed -ErrorAction Stop
        }
        else
        {
            Write-LhEvent -Type Informational -Message 'Execute Products Unit Tests skipped. No products in scope'
        }
        Write-LhEvent -Type Informational -Message 'Execute Products Unit Tests completed'
    }
    catch
    {
        Write-LhEvent -Type Error -InputObject @{Message = "Execute Products Unit Tests failed"; ErrorRecord = $_}
    }
}
