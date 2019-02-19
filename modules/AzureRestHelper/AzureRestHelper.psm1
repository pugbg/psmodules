function Invoke-ArhRestMethod
{
    [CmdletBinding()]
    param
    (
        #Headers
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Headers,

        #Method
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Method,

        #Uri
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        #Body
        [Parameter(Mandatory = $false)]
        [object]$Body,

        #FollowNextLink
        [Parameter(Mandatory = $false)]
        [switch]$FollowNextLink,

        #NextLinkPropertyName
        [Parameter(Mandatory = $false)]
        [string]$NextLinkPropertyName = 'nextLink',

        #NextLinkTokenName
        [Parameter(Mandatory = $false)]
        [string]$NextLinkTokenName
    )

    process
    {
        $InvokeRestMethod_Params = @{
            Method          = $Method
            Headers         = $Headers
            Uri             = $Uri
            UseBasicParsing = $true
        }
        if ($PSBoundParameters.ContainsKey('Body'))
        {
            $InvokeRestMethod_Params.Add('Body', $Body)
        }
        $restResult = Invoke-RestMethod @InvokeRestMethod_Params -ErrorAction Stop
        $restResult

        if ($FollowNextLink.IsPresent)
        {
            while ($restResult.psobject.properties.Name -contains $NextLinkPropertyName -and (-not [string]::IsNullOrEmpty($restResult."$NextLinkPropertyName")))
            {
                remove-variable -Name InvokeRestMethod_Params -ErrorAction SilentlyContinue
                $InvokeRestMethod_Params = @{
                    Method          = $Method
                    Headers         = $Headers
                    UseBasicParsing = $true
                }
                if ($PSBoundParameters.ContainsKey('NextLinkTokenName'))
                {
                
                    $UriBuilder = [System.UriBuilder]::new($Uri)
                    $QueryStringBuilder = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
                    $NextLinkTokenValue = $restResult."$NextLinkPropertyName".Substring($restResult."$NextLinkPropertyName".IndexOf($NextLinkTokenName) + $NextLinkTokenName.Length + 1)
                    $QueryStringBuilder.Add($NextLinkTokenName, $NextLinkTokenValue)
                    $UriBuilder.Query = $QueryStringBuilder.ToString()
                    $InvokeRestMethod_Params.Add('Uri', $UriBuilder.ToString()) 
                }
                elseif ($Method -eq 'Post')
                {
                    $InvokeRestMethod_Params.Add('Body', ($restResult."$NextLinkPropertyName" | ConvertTo-Json -Compress))
                    $InvokeRestMethod_Params.Add('Uri', $Uri) 
                }
                else
                {
                    $InvokeRestMethod_Params.Add('Uri', $restResult."$NextLinkPropertyName") 
                }
                $restResult = Invoke-RestMethod @InvokeRestMethod_Params -ErrorAction Stop 
                $restResult
            }
        }
    }
}

function Get-ArhAuthorizationHeader
{
    [CmdletBinding()]
    param
    (
        #TenantId
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        #AccountId
        [Parameter(Mandatory = $true)]
        [string]$AccountId,

        #Resource
        [Parameter(Mandatory = $false)]
        [string]$Resource = 'https://management.core.windows.net/'
    )

    process
    {
        $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        $SelectedTenantContext = $azProfile.Contexts.Values | Where-Object {($_.Tenant.Id -eq $TenantId) -and ($_.Account.Id -eq $AccountId)}
        if (-not $SelectedTenantContext)
        {
            Write-Error "Account: $AccountId is not authenticated against Tenant: $TenantId"
        }

        $UserId = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::new($AccountId, [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType]::RequiredDisplayableId)
        $context = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$TenantId", $SelectedTenantContext[0].TokenCache)
        $TokenResult = $context.AcquireTokenSilent($Resource, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId, $UserId)
        $TokenResult.CreateAuthorizationHeader()
    }
}