function m-graph
{
    [CmdletBinding()]
    param 
    (
        #Orientation
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('TB', 'BT', 'RL', 'LR', 'TD')]
        [string]$Orientation,

        #Body
        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$Body,

        #classDef
        [Parameter(Mandatory = $false, Position = 2)]
        [hashtable]$classDef
    )

    begin
    {
        $graphInteractions = [System.Collections.Generic.List[string]]::new()
        $graphStyles = [System.Collections.Generic.List[string]]::new()
    }

    process
    {
        #Build Result
        $Result = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        $null = $Result.AppendLine("graph $Orientation")
        $null = $Result.AppendLine("$(. $Body)")
        if ($PSBoundParameters.ContainsKey('classDef'))
        {
            foreach ($key in $classDef.Keys)
            {
                $null = $Result.AppendLine("classDef $key $($classDef[$key])")
            }
        }
        if ($graphInteractions.Count -gt 0)
        {
            $graphInteractions | foreach {
                $null = $Result.AppendLine($_)
            }
        }
        if ($graphStyles.Count -gt 0)
        {
            $graphStyles | foreach {
                $null = $Result.AppendLine($_)
            }
        }

        $Result.ToString()
    }
}

function m-subgraph
{
    [CmdletBinding()]
    param 
    (
        #Id
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id,

        #Attributes
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateScript( {
                $SupportedAttributs = @('Name', 'Style')
                foreach ($attr in $_.keys)
                {
                    if ($attr -notin $SupportedAttributs)
                    {
                        throw "Attribute: '$attr' not supported. Supported attributes: $($SupportedAttributs -join ', ')"
                    }
                }
                $true
            })]
        [hashtable]$Attributes = @{ },

        #Body
        [Parameter(Mandatory = $true, Position = 2)]
        [scriptblock]$Body
    )

    process
    {
        #Build Result
        $Result = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        if ($Attributes.ContainsKey('Name'))
        {
            $null = $Result.AppendLine("subgraph $Id[$($Attributes['Name'])]")
        }
        else
        {
            $null = $Result.AppendLine("subgraph $Id")
        }
        $null = $Result.AppendLine("$(. $Body)")
        $null = $Result.AppendLine("end")
        
        $Result.ToString()

        #Handle Style
        if ($Attributes.ContainsKey('Style'))
        {
            $graphStyles.add("style $Id $($Attributes['Style'])")
        }
    }
}

function m-node
{
    [CmdletBinding()]
    param 
    (
        #Id
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id,

        #Attributes
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateScript( {
                $SupportedAttributs = @('Name', 'Shape', 'LinkTo', 'LinkType', 'LinkText', 'InteractionLink', 'InteractionTooltip', 'Style')
                foreach ($attr in $_.keys)
                {
                    if ($attr -notin $SupportedAttributs)
                    {
                        throw "Attribute: '$attr' not supported. Supported attributes: $($SupportedAttributs -join ', ')"
                    }
                }
                $true
            })]
        [hashtable]$Attributes = @{ }
    )

    begin
    {
        $ShapeDefinition = @{
            'rectangle'         = '[{0}]'
            'round'             = '({0})'
            'circle'            = '(({0}))'
            'rhombus'           = '{{{0}}}'
            'hexagon'           = '{{{{{0}}}}}'
            'parallelogram'     = '[/{0/]'
            'parallelogram alt' = '[\{0}\]'
            'trapezoid'         = '[/{0}\]'
            'trapezoid alt'     = '[\{0}/]'
        }

        $LinkTypeDefinition = @{
            'arrow'  = '-->'
            'open'   = '---'
            'dotted' = '-.->'
            'thick'  = '==>'
        }
    }

    process
    {
        #Validate Shape
        if (-not $Attributes.ContainsKey('Shape'))
        {
            $Attributes['Shape'] = 'rectangle'
        }
        if (-not $ShapeDefinition.ContainsKey($Attributes['Shape']))
        {
            Write-Error "Shape: '$($Attributes['Shape'])' not implemented. Supported Shapes: $($ShapeDefinition.Keys -join ', ')"
        }

        #Validate LinkType
        if (-not $Attributes.ContainsKey('LinkType'))
        {
            $Attributes['LinkType'] = 'arrow'
        }
        if (-not $LinkTypeDefinition.ContainsKey($Attributes['LinkType']))
        {
            Write-Error "LinkType: '$($Attributes['LinkType'])' not implemented. Supported LinkTypes: $($LinkTypeDefinition.Keys -join ', ')"
        }

        #Build Result
        $Result = [System.Text.StringBuilder]::new()
        $null = $Result.Append($Id)
        if ($Attributes.ContainsKey('Name'))
        {
            $null = $Result.Append(($ShapeDefinition[$Attributes['shape']] -f $Attributes['Name']))
        }
        if ($Attributes.ContainsKey('LinkTo'))
        {
            $null = $Result.Append($LinkTypeDefinition[$Attributes['LinkType']])
            if ($Attributes.ContainsKey('LinkText'))
            {
                $null = $Result.Append(" | $($Attributes['LinkText']) | ")
            }
            if ($Attributes['LinkTo'].count -gt 0)
            {
                $CurrentResult = $Result.ToString()
            }
            foreach ($lt in $Attributes['LinkTo'])
            {
                
                $Result = [System.Text.StringBuilder]::new($CurrentResult)
                $null = $Result.AppendLine($lt)
                $Result.ToString()
            }
        }
        else
        {
            $null = $Result.AppendLine()
            $Result.ToString()
        }

        #Handle Interactions
        if ($Attributes.ContainsKey('InteractionLink'))
        {
            if ($Attributes.ContainsKey('InteractionTooltip'))
            {
                $graphInteractions.add("click $Id `"$($Attributes['InteractionLink'])`" `"$($Attributes['InteractionTooltip'])`"")
            }
            else
            {
                $graphInteractions.add("click $Id `"$($Attributes['InteractionLink'])`"")
            }
        }

        #Handle Style
        if ($Attributes.ContainsKey('Style'))
        {
            $graphStyles.add("style $Id $($Attributes['Style'])")
        }
    }
}