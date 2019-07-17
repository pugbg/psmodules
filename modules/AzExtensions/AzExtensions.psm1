function Get-AzeManagementGroup
{
    [CmdletBinding()]
    param
    (
        #Name
        [Parameter(Mandatory = $false)]
        [string]$Name,

        #Recurse
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    process
    {
        $Result = [System.Collections.Generic.List[psobject]]::new() 

        $GetAzManagementGroup_Params = @{ }
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $GetAzManagementGroup_Params = @{
                GroupName = $Name
            }
        }
        Get-AzManagementGroup @GetAzManagementGroup_Params -ErrorAction Stop | foreach {
            $Result.Add($_)
        }


        if ($Recurse.IsPresent)
        {
            $ThisLevelChildMGs = [System.Collections.Generic.List[psobject]]::new()
            foreach ($MG in $Result)
            {
                $ChildMGs = Get-AzManagementGroup -GroupName $MG.Name -Expand | select -ExpandProperty Children 

                foreach ($ChildMG in $ChildMGs)
                {
                    if ($ChildMG.Type -eq "/providers/Microsoft.Management/managementGroups")
                    {
                        Get-AzeManagementGroup -Name $ChildMG.Name -Recurse -ErrorAction Stop | foreach {
                            if ($Result.Id -notcontains $_.Id)
                            {
                                $ThisLevelChildMGs.Add($_)
                            }
                        }
                    }
                }
            }

            $ThisLevelChildMGs | foreach { $Result.Add($_) }
        }

        #Return Results
        $Result
    }
}

function New-AzeResourceGroup
{
    [CmdletBinding()]
    param
    (
        #SubscriptionId
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        #Name
        [Parameter(Mandatory = $true)]
        [string]$Name,

        #Location
        [Parameter(Mandatory = $true)]
        [string]$Location,

        #Tag
        [Parameter(Mandatory = $false)]
        [hashtable]$Tag,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy,

        #ApiVersion
        [Parameter(Mandatory = $false)]
        [string]$ApiVersion = '2019-05-10',

        #oAuthToken
        [Parameter(Mandatory = $true)]
        [AzeOAuthToken]$oAuthToken,

        #PassThru
        [Parameter(Mandatory = $true)]
        [switch]$PassThru
    )

    process
    {
        $InvokeWebRequest_Params = @{
            Uri            = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$($Name)?api-version=$ApiVersion"
            Authentication = 'OAuth'
            Token          = $oAuthToken.AccessTokenAsSecureString
            Method         = 'PUT'
            Body           = (@{location = $location } | convertto-json -Compress)
            ContentType    = 'application/json'
        }
        if ($PSBoundParameters.ContainsKey('Proxy'))
        {
            $InvokeWebRequest_Params.Add('Proxy', $Proxy)
        }
        $WebResult = Invoke-WebRequest @InvokeWebRequest_Params -ErrorAction Stop
        if ($PSBoundParameters.ContainsKey('PassThru'))
        {
            $WebResult.Content | ConvertFrom-Json -ErrorAction Stop
        }
    }
}

function Get-AzeOAuthToken
{
    [CmdletBinding()]
    [OutputType([AzeOAuthToken])]
    param
    (
        #TenantId
        [Parameter(Mandatory = $true,ParameterSetName='UsingServicePrincipal')]
        [Parameter(Mandatory = $true,ParameterSetName='UsingAzContextCache')]
        [string]$TenantId,

        #AccountId
        [Parameter(Mandatory = $true,ParameterSetName='UsingAzContextCache')]
        [string]$AccountId,

        #Resource
        [Parameter(Mandatory = $false)]
        [string]$Resource = 'https://management.core.windows.net/',

        #Timeout
        [parameter(Mandatory = $false)]
        [int]$Timeout = 60,
        
        #AzContext
        [parameter(Mandatory = $false,ParameterSetName='UsingAzContext')]
        [Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext]$AzContext,
        
        #ApplicationId
        [parameter(Mandatory = $true,ParameterSetName='UsingServicePrincipal')]
        [string]$ApplicationId,

        #ApplicationSecret
        [parameter(Mandatory = $true,ParameterSetName='UsingServicePrincipal')]
        [string]$ApplicationSecret
    )

    process
    {
        $Result = [AzeOAuthToken]::new()

        #Get AuthenticationContext
        try
        {
            Write-Information "Get AuthenticationContext started"
            switch ($PSCmdlet.ParameterSetName)
            {
                'UsingAzContext' {
                    Write-Information "Get AuthenticationContext in progress. Using AzContext from InputParameter"
                    $AuthenticationContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$($AzContext.Tenant.Id)", $AzContext.TokenCache)
                    $UserId = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::new($AzContext.Account.Id, [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType]::RequiredDisplayableId)
                    $Task = $AuthenticationContext.AcquireTokenSilentAsync($Resource, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId, $UserId)
                    break
                }
                'UsingAzContextCache' {
                    Write-Information "Get AuthenticationContext in progress. Using AzContext from Cache"
                    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
                    $SelectedTenantContext = $azProfile.Contexts.Values | Where-Object { ($_.Tenant.Id -eq $TenantId) -and ($_.Account.Id -eq $AccountId) }
                    if (-not $SelectedTenantContext)
                    {
                        Write-Error "Account: $AccountId is not authenticated against Tenant: $TenantId"
                    }
                    $UserId = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::new($AccountId, [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType]::RequiredDisplayableId)
                    $AuthenticationContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$TenantId", $SelectedTenantContext[0].TokenCache)
                    $Task = $AuthenticationContext.AcquireTokenSilentAsync($Resource, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId, $UserId)
                    break
                }
    
                'UsingServicePrincipal' {
                    $AdCreds = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential]::new($ApplicationId,$ApplicationSecret)
                    $AuthenticationContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$TenantId")
                    $UserId = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::new($ApplicationId, [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType]::RequiredDisplayableId)
                    $Task = $AuthenticationContext.AcquireTokenAsync($Resource, $AdCreds)
                    break
                }

                default {
                    throw "Unsupported ParameterSetName: $_"
                }
            }

            Write-Information "Get AuthenticationContext completed"
        }
        catch
        {
            throw "Get AuthenticationContext failed. Details $_"
        }
   
        #Get oAuthToken
        try {
            Write-Information "Get oAuthToken started"
            
            if (-not ($Task.Wait([timespan]::FromSeconds($Timeout))))
            {
                throw $task.Exception
            }
            $result.AccessToken = $Task.Result.AccessToken
            $result.AccessTokenType = $Task.Result.AccessTokenType
            $result.AccessTokenAsSecureString = $Task.Result.AccessToken | ConvertTo-SecureString -AsPlainText -Force
            $result.UserInfo = $Task.Result.UserInfo
            $result.IdToken = $Task.Result.IdToken
            $result.TenantId = $Task.Result.TenantId
            Write-Information "Get oAuthToken completed"
        }
        catch {
            throw "Get oAuthToken failed. Details: $_"
        }

        #Return Result
        $result
    }
}

class AzeOAuthToken
{
    [string]$AccessToken
    [string]$AccessTokenType
    [securestring]$AccessTokenAsSecureString
    [psobject]$UserInfo
    [string]$IdToken
    [string]$TenantId
}