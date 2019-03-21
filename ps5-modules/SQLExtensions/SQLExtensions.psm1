function Invoke-SQLQuery
{
	[CmdletBinding()]
	[OutputType([System.Data.DataTable])]
	param 
	(
		#SqlConnection
		[Parameter(Mandatory=$true)]
		[System.Data.SqlClient.SqlConnection]$SqlConnection,	

		#Query
		[Parameter(Mandatory=$true)]
		[string]$Query,

		#TimeoutInSeconds
		[Parameter(Mandatory=$false)]
		[int]$TimeoutInSeconds = 60
	)
	
    Process
    {
		#Execute Query
		try
		{
			Write-Verbose "Execute Query started"

				$Command = $SqlConnection.CreateCommand()
				$Command.CommandText = $Query
				$Command.CommandTimeout = $TimeoutInSeconds
				$SqlResult = $Command.ExecuteReader()
				if ($SqlResult) {
					$result = New-Object -TypeName System.Data.DataTable
					$result.Load($SqlResult)
					if ($result)
					{
						$result
					}
				}
      
			Write-Verbose "Execute Query completed"
		}
		catch
		{
			Write-Error "Execute Query failed. Details: $_" -ErrorAction 'Stop'
		}
    }
}

function Get-SqlInstalledComponents
{
    [CmdletBinding()]
    [OutputType([object])]
    param
    (
        #VersionNumber
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [ValidateSet('100','110','120','130')]
        [string]$VersionNumber,

        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [string]$InstanceName
    )
    
    Begin
    {
        $RegPropsToExclude = 'PSPath','PSParentPath','PSChildName','PSDrive','PSProvider'

        $SqlRegLocation = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
        $SqlSharedComponentsRegLocation = "$SqlRegLocation\$VersionNumber\ConfigurationState"
        $SqlInstanceComponentsRegLocation = "$SqlRegLocation\Instance Names"
    }

    Process
    {
        $Result = @{
            SqlDetected=$false
            Shared=@()
            Instances=@{
                RS=@()
                SQL=@()
            }
        }

        $SqlInstalled = Test-Path -Path $SqlRegLocation
        if ($SqlInstalled)
        {
            $Result['SqlDetected'] = $true

            #Get Shared Components
            try
            {
                $SqlSharedComponentsTemp = Get-ItemProperty -Path $SqlSharedComponentsRegLocation -Name 'SQL_*' -ErrorAction Stop
                $SqlSharedComponentsTemp = $SqlSharedComponentsTemp.psobject.Properties | Where-Object {($RegPropsToExclude -notcontains $_.Name) -and ($_.Value -eq 1)} | select -ExpandProperty Name
                $Result['Shared'] += $SqlSharedComponentsTemp

                if(([int]$VersionNumber) -eq 130)
                {
                    if((Test-Path -Path "$SqlRegLocation\$VersionNumber\Tools\Setup\SQL_SSMS_Adv") -and 
                        ((Get-ItemProperty -Path "$SqlRegLocation\$VersionNumber\Tools\Setup\SQL_SSMS_Adv").FeatureList -like "*SQL_SSMS_Adv=3*"))
                    {
                        $Result['Shared'] += 'SQL_SSMS_Adv'
                        $Result['Shared'] += 'SQL_SSMS_Full'
                    }
                }

                if(([int]$VersionNumber) -gt 130)
                {
                    throw "SSMS check is not implemented yet for versions above 130"
                }
            }
            catch
            {

            }

            #Get RS Instance Components
            try
            {
                $SqlRsInstanceComponentsTemp = Get-ItemProperty -Path "$SqlInstanceComponentsRegLocation\RS" -ErrorAction Stop
                $SqlRsInstanceComponentsTemp = $SqlRsInstanceComponentsTemp.psobject.Properties | Where-Object {($RegPropsToExclude -notcontains $_.Name)} | foreach {
                    [pscustomobject]@{
						Name=$_.Value
                        InstanceName=$_.Name
                    }
                }

                if ($PSBoundParameters.ContainsKey('InstanceName'))
                {
                    $SqlRsInstanceComponentsTemp = $SqlRsInstanceComponentsTemp | Where-Object {$_.InstanceName -eq $InstanceName}
                }

                $Result['Instances']['RS'] += $SqlRsInstanceComponentsTemp
            }
            catch
            {

            }

            #Get Sql Instance Components
            try
            {
                $SqlSqlInstanceComponentsTemp = Get-ItemProperty -Path "$SqlInstanceComponentsRegLocation\Sql" -ErrorAction Stop
                $SqlSqlInstanceComponentsTemp = $SqlSqlInstanceComponentsTemp.psobject.Properties | Where-Object {($RegPropsToExclude -notcontains $_.Name)} | foreach {
                    [pscustomobject]@{
						Name=$_.Value
                        InstanceName=$_.Name
                    }
                }

                if ($PSBoundParameters.ContainsKey('InstanceName'))
                {
                    $SqlSqlInstanceComponentsTemp = $SqlSqlInstanceComponentsTemp | Where-Object {$_.InstanceName -eq $InstanceName}
                }

                $Result['Instances']['Sql'] += $SqlSqlInstanceComponentsTemp
            }
            catch
            {

            }

        }

        #Return Result
        [pscustomobject]$Result
    }

    End
    {

    }
}

function New-SqlConnection
{
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlConnection])]
    param
    (
		#ConnectionString
		[Parameter(Mandatory=$true)]
		[string]$ConnectionString,

        #AccessToken
        [Parameter(Mandatory=$false)]
        [string]$AccessToken
    )

    Process
    {
		#Create New SqlConnection
		try
		{
			Write-Verbose "Create New SqlConnection started"

			$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
			
			$connection.ConnectionString = $connectionString
            if ($PSBoundParameters.ContainsKey('AccessToken'))
            {
                $connection.AccessToken = $AccessToken
            }
			$connection.Open()
			$connection
			Write-Verbose "Create New SqlConnection completed"
		}
		catch
		{
			Write-Error "Create New SqlConnection failed. Details: $_" -ErrorAction 'Stop'
		}
    }
}

function Test-SqlInstanceNameFormat
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]$SqlInstanceName
    )

    Begin 
    {
        $SqlReservedKeywords = @('MSSQLServer', 'ADD', 'ALL', 'ALTER', 'AND', 'ANY', 'AS', 'ASC', 'AUTHORIZATION', 'BACKUP', 'BEGIN', 'BETWEEN', 'BREAK', 'BROWSE', 'BULK', 'BY', 'CASCADE', 'CASE', 'CHECK', 'CHECKPOINT', 'CLOSE', 'CLUSTERED', 'COALESCE', 'COLLATE', 'COLUMN', 'COMMIT', 'COMPUTE', 'CONSTRAINT', 'CONTAINS', 'CONTAINSTABLE', 'CONTINUE', 'CONVERT', 'CREATE', 'CROSS', 'CURRENT', 'CURRENT_DATE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP', 'CURRENT_USER', 'CURSOR', 'DATABASE', 'DBCC', 'DEALLOCATE', 'DECLARE', 'DEFAULT', 'DELETE', 'DENY', 'DESC', 'DISK', 'DISTINCT', 'DISTRIBUTED', 'DOUBLE', 'DROP', 'DUMP', 'ELSE', 'END', 'ERRLVL', 'ESCAPE', 'EXCEPT', 'EXEC', 'EXECUTE', 'EXISTS', 'EXIT', 'EXTERNAL', 'FETCH', 'FILE', 'FILLFACTOR', 'FOR', 'FOREIGN', 'FREETEXT', 'FREETEXTTABLE', 'FROM', 'FULL', 'FUNCTION', 'GOTO', 'GRANT', 'GROUP', 'HAVING', 'HOLDLOCK', 'IDENTITY', 'IDENTITY_INSERT', 'IDENTITYCOL', 'IF', 'IN', 'INDEX', 'INNER', 'INSERT', 'INTERSECT', 'INTO', 'IS', 'JOIN', 'KEY', 'KILL', 'LEFT', 'LIKE', 'LINENO', 'LOAD', 'MERGE', 'NATIONAL', 'NOCHECK', 'NONCLUSTERED', 'NOT', 'NULL', 'NULLIF', 'OF', 'OFF', 'OFFSETS', 'ON', 'OPEN', 'OPENDATASOURCE', 'OPENQUERY', 'OPENROWSET', 'OPENXML', 'OPTION', 'OR', 'ORDER', 'OUTER', 'OVER', 'PERCENT', 'PIVOT', 'PLAN', 'PRECISION', 'PRIMARY', 'PRINT', 'PROC', 'PROCEDURE', 'PUBLIC', 'RAISERROR', 'READ', 'READTEXT', 'RECONFIGURE', 'REFERENCES', 'REPLICATION', 'RESTORE', 'RESTRICT', 'RETURN', 'REVERT', 'REVOKE', 'RIGHT', 'ROLLBACK', 'ROWCOUNT', 'ROWGUIDCOL', 'RULE', 'SAVE', 'SCHEMA', 'SECURITYAUDIT', 'SELECT', 'SEMANTICKEYPHRASETABLE', 'SEMANTICSIMILARITYDETAILSTABLE', 'SEMANTICSIMILARITYTABLE', 'SESSION_USER', 'SET', 'SETUSER', 'SHUTDOWN', 'SOME', 'STATISTICS', 'SYSTEM_USER', 'TABLE', 'TABLESAMPLE', 'TEXTSIZE', 'THEN', 'TO', 'TOP', 'TRAN', 'TRANSACTION', 'TRIGGER', 'TRUNCATE', 'TRY_CONVERT', 'TSEQUAL', 'UNION', 'UNIQUE', 'UNPIVOT', 'UPDATE', 'UPDATETEXT', 'USE', 'USER', 'VALUES', 'VARYING', 'VIEW', 'WAITFOR', 'WHEN', 'WHERE', 'WHILE', 'WITH', 'WITHIN GROUP', 'WRITETEXT')
        $ForbiddenChars = @(' ','\',',',':',';',"'",'&','@','`')
    }

    Process
    {
        if([string]::IsNullOrWhiteSpace($SqlInstanceName)) { throw "The SQL Instance Name cannot be blank" }
        if("$SqlInstanceName".Length -gt 16) { throw "The SQL Instance Name must contain 16 characters or less" }
        if( -not [char]::IsLetter($SqlInstanceName, 0)) { throw "The SQL Instance Name must start with a letter" }
        if("$SqlInstanceName".Substring("$SqlInstanceName".Length - 1) -eq '_') { throw "The SQL Instance Name cannot end with an underscore" }
        $SqlReservedKeywords | foreach { if("$SqlInstanceName" -ilike $_) { throw "The SQL Instance Name cannot contain reserved keywords like $_" } }
        $ForbiddenChars | foreach { if("$SqlInstanceName" -ilike "*$_*") { throw "The SQL Instance Name contains invalid characters ($_)" } }
    }

    End
    {

    }
}

