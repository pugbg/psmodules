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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Get','Patch')]
        [string]$Method,

		#Uri
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        #Body
        [Parameter(Mandatory=$false)]
        [object]$Body
    )

    process
    {
        $InvokeRestMethod_Params = @{
            Method=$Method
            Headers=$Headers
            Uri=$Uri
            UseBasicParsing=$true
        }
        if ($PSBoundParameters.ContainsKey('Body'))
        {
            $InvokeRestMethod_Params.Add('Body',$Body)
        }
        $restResult = Invoke-RestMethod @InvokeRestMethod_Params -ErrorAction Stop
		$restResult

        while ($restResult.nextLink)
        {
            $restResult = Invoke-RestMethod -Method 'Get' -Headers $Headers -Uri $restResult.nextLink -UseBasicParsing
            $restResult
        }
    }
}

function Get-ArhAuthorizationHeader
{
    [CmdletBinding()]
	param
	(
		#TenantId
        [Parameter(Mandatory=$true)]
        [string]$TenantId,

        #AccountId
        [Parameter(Mandatory=$true)]
        [string]$AccountId,

        #Resource
        [Parameter(Mandatory=$false)]
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

        $context = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$TenantId",$SelectedTenantContext[0].TokenCache)
        $TokenResult = $context.AcquireTokenSilent($Resource,[Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId)
        $TokenResult.CreateAuthorizationHeader()
    }
}