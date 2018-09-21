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