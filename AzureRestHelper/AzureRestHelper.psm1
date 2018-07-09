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
        [ValidateSet('Get')]
        [string]$Method,

		#Uri
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri
    )

    process
    {
        $restResult = Invoke-RestMethod -Method $Method -Headers $Headers -Uri $Uri -UseBasicParsing
		$restResult.value

        while ($restResult.nextLink)
        {
            $restResult = Invoke-RestMethod -Method $Method -Headers $Headers -Uri $restResult.nextLink -UseBasicParsing
            $restResult.value
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
        [ValidateNotNullOrEmpty()]
        $TenantId
    )

    process
    {
		$AzRmContext = Get-AzureRmContext
		$TokenCache = $AzRmContext.TokenCache.ReadItems()
		$TenantToken = $TokenCache | Where-Object {$_.TenantId -eq $TenantId}
		if (-not $TenantToken)
		{
			throw "No token found for Tenant: $TenantId"
		}
		else 
		{
			"Bearer "+ $TenantToken.AccessToken
		}
    }
}