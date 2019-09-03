#requires -module @{ModuleName='VSTeam';RequiredVersion='6.3.3'}

[cmdletbinding()]
param
(
    [parameter(Mandatory = $true)]
    [string]$AdoOrganizationName,

    [parameter(Mandatory = $true)]
    [string]$AdoPat
)

process
{
    Write-Information -Message "Invoke IntegrationTests in progress. Connect To AzureDevOps started"
    $null = Set-VSTeamAccount -Account $AdoOrganizationName -PersonalAccessToken $AdoPat -Version AzD -ErrorAction Stop
    Write-Information -Message "Invoke IntegrationTests in progress. Connect To AzureDevOps completed"
}