function ConvertTo-String
{
  [CmdletBinding()]
  param
  (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            If ('Hashtable','OrderedDictionary','AXNodeConfiguration','PSBoundParametersDictionary' -contains $_.GetType().Name)
            {
                $true
            }
            else
            {
                throw "Supported InputTypes are 'Hashtable' and 'OrderedDictionary'"
            }
        })]
        $InputObject,

        [Parameter(Mandatory=$false)]
        [switch]$DoNotFormat
    )
  
    Begin
    {
        function priv_Escape-SpecialChars
        {  
            param
            (
                [Parameter(Mandatory=$true, Position = 0)]
                [AllowEmptyString()]
                [string]$InputObject
            )

            if([string]::IsNullOrEmpty($InputObject))
            {
                return ""
            }
            else
            {
                [string]$ParsedText = $InputObject

                if($ParsedText.ToCharArray() -icontains "'")
                {
                    $ParsedText = $ParsedText -replace "'","''"
                }

                return $ParsedText
            }
        }
    }

    Process
    {
        $sb = new-object System.Text.StringBuilder

        $null = $sb.AppendLine('@{')

        foreach ($key in $InputObject.Keys)
        {
		    if ($InputObject[$key])
		    {
			    switch ($inputObject[$key].GetType().Name)
			    {
                    ### ScriptBlocks
			        'ScriptBlock' {
				        $null = $sb.AppendLine("$key = `{$($inputObject[$key].ToString())`}")
				        break
			        }

                    ### Strings and Enums
			        { @('String','ActionPreference') -contains $_ }  { 
                        [string]$itemText = "{0} = '{1}'" -f "$key", $(priv_Escape-SpecialChars -InputObject $inputObject[$key])
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### String Arrays
			        'String[]' {
                        [string]$itemText = "{0} = @({1})" -f "$key", "$($($inputObject[$key] | foreach { "'$(priv_Escape-SpecialChars -InputObject $_)'" }) -join ", ")"
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### Numerics
			        { ($_ -ilike '*int*') -or (@('single','double','decimal','SByte','Byte') -icontains $_) } {
                        [string]$itemText = "{0} = {1}" -f "$key", $($inputObject[$key]).ToString()
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### Nested Hashtables (recursive call)
			        {'Hashtable','OrderedDictionary','PSBoundParametersDictionary' -contains $_}  { 
                        [string]$itemText = "{0} = {1}" -f "$key", $(ConvertTo-String -InputObject $inputObject[$key] -DoNotFormat)
				        $null = $sb.AppendLine($itemText) 
				        break
			        }

                    ### Nested Hashtable Arrays (recursive call)
			        {'Hashtable[]','OrderedDictionary[]','PSBoundParametersDictionary[]' -contains $_}  { 
						$NewLineStr = [Environment]::NewLine
						$JoinSeparator = ",$NewLineStr"
                        [string]$itemText = "{0} = @($NewLineStr{1}$NewLineStr)" -f "$key", "$($($inputObject[$key] | foreach { ConvertTo-String -InputObject $_ -DoNotFormat }) -join $JoinSeparator)"
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### Booleans and Switches
                    { @('Boolean','SwitchParameter') -contains $_ } {
                        [string]$itemText = '{0} = ${1}' -f "$key", $($inputObject[$key].ToString())
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### PSCustomObject (NoteProperties only)
                    'PSCustomObject' {
                        # Convert to hashtable
                        $propHash = @{}
                        foreach ($prop in $inputObject[$key].PSObject.Properties)
                        {
                            $propHash[$prop.Name] = $prop.Value
                        }

                        [string]$itemText = '{0} = $([PSCustomObject] {1})' -f "$key", $(ConvertTo-String -InputObject $propHash -DoNotFormat)
				        $null = $sb.AppendLine($itemText) 
				        break
			        }

                    ### DateTime
                    'DateTime' {
                        [string]$itemText = "{0} = '{1}'" -f "$key", $($inputObject[$key].ToUniversalTime().ToString("dd.MM.yyyy HH.mm:ss UTC", [CultureInfo]::InvariantCulture))
				        $null = $sb.AppendLine($itemText) 
				        break
			        }

			        Default {
				        Write-Warning "Serializing not supported key: $key that contains: $_"
                        [string]$itemText = '{0} = {1}' -f "$key", $($inputObject[$key].ToString())
				        $null = $sb.AppendLine($itemText)
			        }
			    }
		    }
		    else
		    {
				$null = $sb.AppendLine('{0} = $null' -f "$key")
		    }
        }

        $null =  $sb.AppendLine('}')
    
        $result = $sb.ToString()

        if($DoNotFormat.IsPresent)
        {
            $result.Trim([environment]::NewLine)
        }
        else
        {
            ConvertTo-TabifiedString -ScriptText $result
        }
    }

    End
    {

    }
}

function ConvertTo-Hashtable
{

	param
	(
		[ValidateScript({
        $TempParam = $_
		switch ($TempParam.GetType().Fullname)
		{
			'System.String' {
				try
				{
					$obj = ConvertFrom-Json -InputObject $TempParam -ErrorAction Stop
					$Script:InputObjectData = $obj.psobject.Properties
				}
				catch
				{
					throw "InputObject is not a valid json string"
				}
				break
			}
			default {
				$Script:InputObjectData = $TempParam.psobject.Properties
			}
		}
		$true
	})]
		$InputObject
	)

	begin
	{
		$DepthThreshold = 32

		function Get-IOProperty
		{
			param
			(
				[Parameter(Mandatory=$true)]
				[System.Management.Automation.PSPropertyInfo[]]$Property,

				[Parameter(Mandatory=$true)]
				[int]$CurrentDepth
			)
			
			#Increse and chech Depth
			$CurrentDepth++
			if ($Function:Depth -ge $DepthThreshold)
			{
				Write-Error -Message "Converting to Hashtable reached Depth Threshold of 32 on $($Property.Name -join ',')" -ErrorAction Stop
			}

			$Ht = [hashtable]@{}
			foreach ($Prop in $Property)
			{
				if ($Prop.Value)
				{
					switch ($Prop.TypeNameOfValue)
					{
						'System.String' {
							$ht.Add($Prop.Name,$Prop.Value)
							break
						}
						'System.Boolean' {
							$ht.Add($Prop.Name,$Prop.Value)
							break
						}
						'System.DateTime' {
							$ht.Add($Prop.Name,$Prop.Value.ToString())
							break
						}
						{$_ -ilike '*int*'} {
							$ht.Add($Prop.Name,$Prop.Value)
							break
						}
						default {
							$ht.Add($Prop.Name,(Get-IOProperty -Property $Prop.Value.psobject.Properties -CurrentDepth $CurrentDepth))
						}
					}
				}
				else
				{
					$ht.Add($Prop.Name,$null)
				}
			}
			$Ht
		}
	}
  
	process
	{
		$CurrentDepth = 0
		Get-IOProperty -Property $InputObjectData -CurrentDepth $CurrentDepth
	}
  
	end
	{
	}
}

function ConvertTo-TabifiedString
{
	[CmdletBinding()]
	Param
	(
		$ScriptText
	) 
	
	$CurrentLevel = 0
	$ParseError = $null
	$Tokens = $null
	$AST = [System.Management.Automation.Language.Parser]::ParseInput($ScriptText, [ref]$Tokens, [ref]$ParseError) 
	
	if($ParseError) { 
	$ParseError | Write-Error
	throw 'The parser will not work properly with errors in the script, please modify based on the above errors and retry.'
	}
	
	for($t = $Tokens.Count -2; $t -ge 1; $t--) {
		
	$Token = $Tokens[$t]
	$NextToken = $Tokens[$t-1]
		
	if ($token.Kind -match '(L|At)Curly') { 
		$CurrentLevel-- 
	}  
		
	if ($NextToken.Kind -eq 'NewLine' ) {
		# Grab Placeholders for the Space Between the New Line and the next token.
		$RemoveStart = $NextToken.Extent.EndOffset  
		$RemoveEnd = $Token.Extent.StartOffset - $RemoveStart
		$tabText = "`t" * $CurrentLevel 
		$ScriptText = $ScriptText.Remove($RemoveStart,$RemoveEnd).Insert($RemoveStart,$tabText)
	}
		
	if ($token.Kind -eq 'RCurly') { 
		$CurrentLevel++ 
	}     
	}

	$ScriptText
}

function Resolve-ObjectProperty
{
    [CmdletBinding()]
    [OutputType([object])]
    param
    (
        #InputObject
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [object[]]$InputObject,

        #PropertyName
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$PropertyName,

		#PropertyValueReference
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [hashtable]$PropertyValueReference
    )
    
    Begin
    {
          
    }

    Process
    {
		foreach ($object in $InputObject)
		{
			if ($object.psobject.Properties.Name -contains $PropertyName)
			{
				if ($PropertyValueReference.ContainsKey(($object.$PropertyName)))
				{
					$object.$PropertyName = $PropertyValueReference[$object.$PropertyName]			
				}
			}
		}
		$InputObject
    }

    End
    {

    }
}

function Import-PSDataFile
{
    [CmdletBinding()]
    Param 
	(
        [Parameter(Mandatory)]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable] $FilePath    
    )
    return $FilePath
}

function ConvertFrom-JsonString
{
    [CmdletBinding()]
    param
    (
        #InputObject
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        $InputObject
    )
    
    Begin
    {
          
    }

    Process
    {
		    add-type -assembly system.web.extensions
			$ps_js = New-Object system.web.script.serialization.javascriptSerializer -ErrorAction Stop
            $ps_js.DeserializeObject($InputObject) | foreach {
                New-Object -TypeName psobject -Property $_ -ErrorAction Stop
            }
			
    }

    End
    {

    }
}

function New-DynamicConfiguration
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Definition
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='NoRemoting_Default')]
        [scriptblock]$Definition
    )
    
    Begin
    {
          
    }

    process
	{
		$blockDefinition = $Definition.ToString() + "`n" + 'Export-ModuleMember -Variable *'
		$result = . New-Module -AsCustomObject -ScriptBlock ([scriptblock]::Create($blockDefinition))
		$SubProperties = $result.psobject.Properties | Where-Object {$_.TypeNameOfValue -eq 'System.Management.Automation.ScriptBlock'} -ErrorAction Stop
		foreach ($item in $SubProperties)
		{
			$result."$($item.Name)" = New-DynamicConfiguration -Definition $result."$($item.Name)" -ErrorAction Stop
		}
		$result
	}

    End
    {

    }
}

Function Get-DerivedType
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$BaseType,

        [Parameter(Mandatory=$true)]
        [ValidateSet('AppDomain','File')]
        [string]$Scope,

        [Parameter(Mandatory=$false)]
        [switch]$Recurse
    )

    DynamicParam
    {

            #Assembly
            $Assembly_AttrColl = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $Assembly_Param = new-object -Type System.Management.Automation.RuntimeDefinedParameter('Assembly',[string[]],$Assembly_AttrColl)

            if ($Scope -eq 'AppDomain')
            {
                $Assembly_Attr1 = new-object System.Management.Automation.ParameterAttribute
                $Assembly_Attr1.Mandatory = $false
                $Assembly_Param.Attributes.Add($Assembly_Attr1)

                $Assembly_Attr2 = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList ([System.AppDomain]::CurrentDomain.GetAssemblies().FullName)
                $Assembly_Param.Attributes.Add($Assembly_Attr2)
            }
            else
            {
                $Assembly_Attr1 = new-object System.Management.Automation.ParameterAttribute
                $Assembly_Attr1.Mandatory = $true
                $Assembly_Param.Attributes.Add($Assembly_Attr1)
            }

            $DynamicParams = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $DynamicParams.Add('Assembly',$Assembly_Param)

            $DynamicParams
    }

    begin
    {

        Function priv_Resolve-DerivedType
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true)]
                [string]$BaseType,

                [Parameter(Mandatory=$true)]
                [System.Reflection.Assembly[]]$Assembly,

                [Parameter(Mandatory=$false)]
                [switch]$Recurse
            )

            process
            {
                $Assembly.ExportedTypes | foreach {

                    if ($_.BaseType.FullName -eq $BaseType)
                    {
                        $_
                        if ($Recurse.IsPresent)
                        {
                            priv_Resolve-DerivedType -BaseType $_.FullName -Assembly $Assembly -Recurse:$Recurse.IsPresent
                        }
                    }

                }
            }
        }

    }

    process
    {
		if ($Scope -eq 'AppDomain' -and $PSBoundParameters.ContainsKey('Assembly'))
		{
			$ResolvedAssembly = [System.Reflection.Assembly]::Load($PSBoundParameters['Assembly'])
		}
		else
		{
			$ResolvedAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies()
		}

        priv_Resolve-DerivedType -BaseType $BaseType -Recurse:$Recurse.IsPresent -Assembly $ResolvedAssembly
    }

    end
    {
    
    }    

}

function Get-Version
{
    [CmdletBinding()]
    [OutputType([System.Version])]
    param
    (
        #InputObject
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$InputObject
    )
    
    Begin
    {
          
    }

    Process
    {
		[ref]$Version = $null
		if ([System.Version]::TryParse($InputObject,$Version))
		{
			if ($Version.Value.Revision -eq -1)
			{
				$Revision = 0
			}
			else
			{
				$Revision = $Version.Value.Revision
			}
			if ($Version.Value.Build -eq -1)
			{
				$Build = 0
			}
			else
			{
				$Build = $Version.Value.Build
			}
		}
		else
		{
			throw "$InputObject cannot be parsed as version"
		}

		[System.Version]::new($Version.Value.Major,$Version.Value.Minor,$Build,$Revision)
    }

    End
    {

    }
}

function Update-HTMLSpecialChars
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        #HTML String to format
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$StringAsHTML
    )
    
    Begin
    {
    }

    Process
    {
		try
		{
			$StringAsHTML = $StringAsHTML.Replace("�","&Auml;") #Capital A-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&auml;") #Lowercase a-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&Eacute;") #Lowercase a-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&eacute;") #Lowercase E-acute
			$StringAsHTML = $StringAsHTML.Replace("�","&Ouml;") #Capital O-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&ouml;") #Lowercase o-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&Uuml;") #Capital U-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&uuml;") #Lowercase u-umlaut
			$StringAsHTML = $StringAsHTML.Replace("�","&szlig;") #SZ ligature
			$StringAsHTML = $StringAsHTML.Replace("�","&laquo;") #Left angle quotes
			$StringAsHTML = $StringAsHTML.Replace("�","&raquo;") #Right angle quotes
			$StringAsHTML = $StringAsHTML.Replace('�',"&#132;") #Left lower quotes
			$StringAsHTML = $StringAsHTML.Replace('�',"&#147;") #Left quotes
			$StringAsHTML = $StringAsHTML.Replace('�',"&#148;") #Right quotes
			$StringAsHTML = $StringAsHTML.Replace("�","&#176;") #Degree sign (Grad)
			$StringAsHTML = $StringAsHTML.Replace("�","&euro;") #Euro
			$StringAsHTML = $StringAsHTML.Replace("�","&pound;") #Pound Sterling

			return $StringAsHTML
		}
		catch
		{
			throw "Special chars could not be replaced for string: $string"
		}
    }

    End
    {

    }
}

function Test-JsonSchema
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        #InputObject
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$InputObject,

		#Schema
		[Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$Schema,

		#ValidationMessage
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [ref]$ValidationMessage
    )
    
    Begin
    {
          
    }

    Process
    {
		$JSchema = [Newtonsoft.Json.Schema.JSchema, Newtonsoft.Json.Schema, Version=3.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed]::Parse($Schema)
		$JObject = [Newtonsoft.Json.Linq.JToken, Newtonsoft.Json, Version=10.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed]::Parse($InputObject)
		if ($PSBoundParameters.ContainsKey('ValidationMessage'))
		{
			[Newtonsoft.Json.Schema.SchemaExtensions, Newtonsoft.Json.Schema, Version=3.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed]::IsValid($JObject,$JSchema,$ValidationMessage)
		}
		else
		{
			[Newtonsoft.Json.Schema.SchemaExtensions, Newtonsoft.Json.Schema, Version=3.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed]::IsValid($JObject,$JSchema)
		}
    }

    End
    {

    }
}

function Split-Object
{
    [CmdletBinding()]

    param 
    (
        #ByProperty
        [Parameter(Mandatory = $true, ParameterSetName = 'ByProperty')]
        [string]$ByProperty,

        #InputObject
        [Parameter(Mandatory = $true, ParameterSetName = 'ByProperty')]
        [object[]]$InputObject,

        #ChunkSize
        [Parameter(Mandatory = $true)]
        [int]$ChunkSize
    )

    begin
    {
        $ioEndIdx = 0
        $o = 0
    }

    process
    {
        for ($ioStartIdx = 0; $ioStartIdx -lt $InputObject.Count; $ioStartIdx = $ioEndIdx + 1)
        {
            # Calculate InputObject End Index ($ioEndIdx)
            for ($ioEndIdxCandidate = $ioStartIdx; $ioEndIdxCandidate -lt $InputObject.Count; $ioEndIdxCandidate++)
            {
                $curSize = ($InputObject[$ioStartIdx..$ioEndIdxCandidate]."$ByProperty".Count | Measure-Object -Sum).Sum
        
                $ioEndIdx = [math]::Max($ioStartIdx, $ioEndIdxCandidate - 1)
                if ($curSize -gt $ChunkSize)
                {
                    break;
                }
            }

            # Check if a single InputObject item contains a block larger than the ChunkSize
            if (($ioStartIdx -eq $ioEndIdx) -and ($curSize -gt $ChunkSize))
            {
                $part = 0
                #Split the Object into multiple chunks
                for ($ioPropStartIdx = 0; $ioPropStartIdx -lt $InputObject[$ioStartIdx]."$ByProperty".Count; $ioPropStartIdx = $ioPropStartIdx + $ChunkSize)
                {
                    $ioClone = $InputObject[$ioStartIdx] | ConvertTo-Json -Compress -Depth 10 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    $ioClone."$ByProperty" = $InputObject[$ioStartIdx]."$ByProperty"[$ioPropStartIdx..($ioPropStartIdx + $ChunkSize -1)]
                    [pscustomobject]@{
                        ChunkId = $o
                        Part    = $part
                        Object  = $ioClone
                    }
                    $part++       
                }
            }
            else 
            {
                [pscustomobject]@{
                    ChunkId = $o
                    Part = 0
                    Object  = $InputObject[$ioStartIdx..$ioEndIdx]
                }
            
            }
            $o++
        }
    }
}

function Merge-Object
{
    [CmdletBinding()]

    param 
    (
        #ByProperty
        [Parameter(Mandatory = $true, ParameterSetName = 'ByProperty')]
        [string]$ByProperty,

        #InputObject
        [Parameter(Mandatory = $true, ParameterSetName = 'ByProperty')]
        [object[]]$InputObject
    )

    process
    {
        $InputObject | Where-Object {$_.Part -eq 0} | foreach {
            $result = $_ | ConvertTo-Json -Compress -Depth 10 -ErrorAction Stop | ConvertFrom-Json
            $OtherParts = $InputObject | Where-Object {$_.ChunkId -eq $result.ChunkId}
            if (($OtherParts | Measure-Object).Count -gt 1)
            {
                $result.Object."$ByProperty" = $OtherParts.Object."$ByProperty"
            }
            $result.Object
        }
    }
}

function Set-JsonSchemaLicense
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #LicensseKey
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$LicensseKey
    )
    
    Begin
    {
          
    }

    Process
    {
		[Newtonsoft.Json.Schema.License]::RegisterLicense($LicensseKey)
    }

    End
    {

    }
}