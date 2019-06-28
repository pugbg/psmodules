function Connect-AahServiceConnection
{
    [CmdletBinding()]
    param
    (
        #ServiceConnection
        [Parameter(Mandatory=$true)]
        [psobject]$ServiceConnectionId,

        #PassThru
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    process
    {
        #Get ServiceConnection
        try
        {
            Write-Information "Get ServiceConnection started"

            $ServiceConnection = Get-VstsEndpoint -Name $ServiceConnectionId -Require

            Write-Information "Get ServiceConnection completed"
        }
        catch
        {
            throw "Get ServiceConnection failed. Details: $_"
        }

        #Connect using ServiceConnection
        try
        {
            Write-Information "Connect using ServiceConnection started"

            switch ($ServiceConnection.Auth.scheme)
            {
                'ServicePrincipal' {
                    
                    switch ($ServiceConnection.Auth.Parameters.AuthenticationType)
                    {
                        'spnKey' {

                            Write-Information "Connect using ServiceConnection in progress. Connecting to:'' using 'ServicePrincipal with spnKey'"
                            $ConnectAzAccount_Params = @{
                                ContextName="aah_$ServiceConnectionId"
                                ServicePrincipal=$true
                                Tenant=$ServiceConnection.Auth.Parameters.TenantId
                                Subscription=$ServiceConnection.Data.subscriptionId
                                Credential=[System.Management.Automation.PSCredential]::new($ServiceConnection.Auth.Parameters.ServicePrincipalId,(ConvertTo-SecureString $ServiceConnection.Auth.Parameters.ServicePrincipalKey -AsPlainText -Force))
                            }
                            $profile = Connect-AzAccount @ConnectAzAccount_Params -ErrorAction Stop
                            if ($PassThru.IsPresent)
                            {
                                $profile
                            }
                        }

                        default { throw "Unsupported ServiceConnection AuthenticationType: $_" }
                    }

                    break
                }


                default { throw "Unsupported ServiceConnection Auth Schema: $_" }
            }

            Write-Information "Connect using ServiceConnection completed"
        }
        catch
        {
            throw "Connect using ServiceConnection failed. Details: $_"
        }
    }
}

function Disconnect-AahServiceConnection
{
    [CmdletBinding()]
    param
    (
        #ServiceConnection
        [Parameter(Mandatory=$true,ParameterSetName='Specific')]
        [psobject[]]$ServiceConnectionId,

        #All
        [Parameter(Mandatory=$true,ParameterSetName='All')]
        [switch]$All
    )

    process
    {
        #Get ServiceConnections in Scope
        try
        {
            Write-Information "Get ServiceConnections in Scope started"

            $ServiceConnectionsInScope = [System.Collections.Generic.List[string]]::New()

            switch($PSCmdlet.ParameterSetName)
            {
                'Specific' {
                    $ContextNamesInScope = $ServiceConnectionId | foreach {"aah_$_"}
                    Get-AzContext -ListAvailable | Where-Object {$_.Name -in $ContextNamesInScope} | foreach {
                        $ServiceConnectionsInScope.Add($_.Name)
                    }
                    break
                }
    
                'All' {
                    $ServiceConnections = Get-AzContext -ListAvailable | Where-Object {$_.Name -like 'aah_*'} | foreach {
                        $ServiceConnectionsInScope.Add($_.Name)
                    }
                    break
                }
    
                default { throw "Unsupported ParameterSetName: $_" }
            }

            Write-Information "Get ServiceConnections in Scope completed"
        }
        catch
        {
            throw "Get ServiceConnections in Scope failed. Details: $_"
        }

        #Disconnect ServiceConnections
        try
        {
            Write-Information "Disconnect ServiceConnections started"

            if ($ServiceConnectionsInScope.Count -gt 0)
            {
                $ServiceConnectionsInScope | foreach {
                    try
                    {
                        Write-Warning "Disconnect ServiceConnections in progress. Disconnecting: $_"
                        Disconnect-AzAccount -ContextName $_ -ErrorAction Stop
                    }
                    catch
                    {
                        Write-Warning "Disconnect ServiceConnections in progress. Failed to disconnect: $_"
                    }
                }
            }
            else
            {
                Write-Information "Disconnect ServiceConnections skipped. No ServiceConnections in scope"
            }
        }
        catch
        {
            throw "Disconnect ServiceConnections failed. Details: $_"
        }
    }
}