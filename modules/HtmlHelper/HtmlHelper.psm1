#region Public Functions

function htmldoc
{
    [CmdletBinding()]
    param
    (
        #Body
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock]$Body,

        #CssStyle
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$CssStyle,

        #JSScript
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$JSScript
    )

    process
    {
        #Build Result
        $Result = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        $null = $Result.AppendLine("<html>")
        $null = $Result.AppendLine("<head>")
        if ($PSBoundParameters.ContainsKey('CssStyle'))
        {
            $null = $Result.AppendLine("<style>")
            $null = $Result.AppendLine($CssStyleToUse)
            $null = $Result.AppendLine("</style>")
        }
        $null = $Result.AppendLine("<body>")
        $null = $Result.AppendLine("$(& $Body)")
        if ($PSBoundParameters.ContainsKey('JSScript'))
        {
            $null = $Result.AppendLine("<script>")
            $null = $Result.AppendLine($JavaScriptTouse)
            $null = $Result.AppendLine("</script>")
        }
        $null = $Result.AppendLine("</body>")
        $null = $Result.AppendLine("<html>")

        $Result.ToString()
    }
}

function paragraph
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Attributes,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$Body
    )

    process
    {
        #Process Attributes
        if ($PSBoundParameters.ContainsKey('Attributes'))
        {
            #Check for Custom Style
            if ($Attributes.ContainsKey('style'))
            {
                $CustomStyle = $Attributes['style']
            }

            #Check for Custom Class
            if ($Attributes.ContainsKey('class'))
            {
                $CustomClass = $Attributes['class']
            }
        }

        #Build Result
        $Result = @(
            "<p style=`"$CustomStyle`" class=`"$CustomClass`">$(& $Body)</p>"
        )

        #Return Result
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        foreach ($line in $Result)
        {
            $null = $StringBuilder.AppendLine($line)
        }
        $StringBuilder.ToString()
    }
}

function table
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$Body
    )

    process
    {
        #Build Result
        $Result = @(
            "<div style=`"display:inline-block; border:1px solid #000`">$(& $Body)</div>"
        )
		
        #Return Result
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        foreach ($line in $Result)
        {
            $null = $StringBuilder.AppendLine($line)
        }
        $StringBuilder.ToString()
    }
}

function table-column
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Label,

        [Parameter(Mandatory = $false, Position = 1)]
        [hashtable]$style,

        [Parameter(Mandatory = $true, Position = 3)]
        [scriptblock]$Body
    )

    process
    {
        #Process Styles
        if ($PSBoundParameters.ContainsKey('Style'))
        {
            #Check for Custom Class
            if ($style.ContainsKey('class'))
            {
                $CustomClass = " $($style['class'] -join ' ')"
            }

            #Check for Custom Width
            if ($style.ContainsKey('width'))
            {
                $CustomWidth = $style['width']
            }

            #Check for white-space
            if ($style.ContainsKey('white-space'))
            {
                $CustomWhiteSpace = $style['white-space']
            }
        }

        #Build Result
        $Result = @(
            "<div style=`"display:table-cell; border:1px solid #000; width:$CustomWidth; white-space:$CustomWhiteSpace;`">"
            "<div style=`"display:table-row; border:1px solid #000; white-space:$CustomWhiteSpace;`" class=`"label`">$Label</div>"
        )
		
        #Check if Body contains SubElements
        $CheckForSubElements = Get-AstStatement -Ast $Body.Ast -Type CommandAst | Where-Object { $SubElements -contains $_.GetCommandname() }
        if ($CheckForSubElements)
        {
            #In case Body contains SubElements
            $Result += "<div style=`"display:table-row; border:1px solid #000; white-space:$CustomWhiteSpace;`">$(& $Body)</div>"
        }
        else
        {
            #In case Body contains only Data
            $Result += "<div style=`"display:table-row; border:1px solid #000; white-space:$CustomWhiteSpace;`" class=`"cell$CustomClass`">$(& $Body)</div>"
        }
        $Result += '</div>'

        #Return Result
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        foreach ($line in $Result)
        {
            $null = $StringBuilder.AppendLine($line)
        }
        $StringBuilder.ToString()
    }
}

function table-row
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$Body
    )

    process
    {
        #Build Result
        $Result = @(
            "<div style=`"display:table-row; border:1px solid #000`">$(& $Body)</div>"
        )

        #Return Result
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop
        foreach ($line in $Result)
        {
            $null = $StringBuilder.AppendLine($line)
        }
        $StringBuilder.ToString()
    }
}

#endregion

#region internal variables

$SubElements = @(
    'table-column'
    'table-row'
    'table'
)

#endregion