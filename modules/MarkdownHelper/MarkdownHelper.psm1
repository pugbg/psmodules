function Get-CNMarkdownTable {

  [CmdletBinding()]
  [Outputtype([System.Collections.Generic.List[Markdig.Extensions.Tables.Table]])]
  param
  (
    [Parameter(Mandatory)]
    [System.IO.FileInfo] $FilePath,

    [Parameter()]
    [string[]] $TableHeader
  )

  $markdown = ConvertFrom-Markdown -Path $FilePath.FullName
  $tables = [System.Collections.Generic.List[Markdig.Extensions.Tables.Table]]::new()
  $markdown.Tokens | ForEach-Object -Process {
    if ($_ -is [Markdig.Extensions.Tables.Table]) {
      if ($PSBoundParameters.ContainsKey('TableHeader')) {
        $headerStrings = $_[0] | ForEach-Object { $_.Inline.ToString() }
        $desiredTable = $true
        foreach ($th in $TableHeader) {
          if ($th -notin $headerStrings) {
            $desiredTable = $false
          }
        }
        if ($desiredTable) {
          $tables.Add($_)
        }
      } else {
        $table.add($_)
      }
    }
  }

  #return tables
  $PSCmdlet.WriteObject($tables, $false)
}
  
function Get-CNMarkdownTableItem {
  
  [CmdletBinding(DefaultParameterSetName = 'ByTable')]
  param
  (
    [Parameter(Mandatory, ParameterSetName = 'ByFile')]
    [System.IO.FileInfo] $FilePath,

    [Parameter(Mandatory, ParameterSetName = 'ByFile')]
    [string[]] $TableHeader,

    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByTable')]
    [Markdig.Extensions.Tables.Table] $MarkdownTable,

    [Parameter()]
    [switch]$IncludeHeaders,

    [Parameter()]
    [int[]] $Row,

    [Parameter()]
    [int[]] $Column
  )

  if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
    $table = Get-CNMarkdownTable -FilePath $FilePath -TableHeader $TableHeader
  } else {
    $table = $MarkdownTable
  }

  #Get items
  if ($table) {
    if ($IncludeHeaders.IsPresent) {
      $tableBody = $table
    } else {
      $tableBody = $table | Select-Object -Skip 1
    }

    if ($PSBoundParameters.ContainsKey('Row')) {
      $tableBody = $tableBody[$row]
    }
    if ($PSBoundParameters.ContainsKey('Column')) {
      $tableBody | ForEach-Object -Process { $_[$Column] }
    } else {
      $tableBody
    }

  } else {
    throw "Table with headers: '$($TableHeader -join ', ')' not found"
  }
}
  
function Add-CNMarkdownTableRow {
  
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory)]
    [System.IO.FileInfo] $FilePath,

    [Parameter(Mandatory)]
    [string[]] $TableHeader,

    [Parameter(Mandatory)]
    [string[]] $Column,

    [Parameter()]
    [int] $Index = 0,

    [Parameter()]
    [switch] $Force
  )

  $table = Get-CNMarkdownTable -FilePath $FilePath -TableHeader $TableHeader

  #Update table
  if ($table) {
    #get table headers
    $existingTableHeaders = $table[0] | ForEach-Object -Process { $_.Inline.ToString() }

    #calculate row columns
    if ($Column.Count -ne $existingTableHeaders.Count) {
      if ($Force.IsPresent) {
        $columnDif = $existingTableHeaders.Count - $Column.Count
        for ($i = 0; $i -lt $columnDif; $i++) {
          $Column += ''
        }
      } else {
        throw "Inserting row with: $($Column.Count) columns in table with $($existingTableHeaders.Count) columns not allowed. Use -Force to override"
      }
    }

    #append on specific line
    $fileContent = [System.Collections.Generic.List[string]]::new()
    Get-Content -Path $FilePath | ForEach-Object -Process {
      $fileContent.Add($_)
    }
    if ($Index -ge 0) {
      $fileLineToInsert = $table[0].Line + 2 + $Index
    } else {
      $fileLineToInsert = $table[-1].Line + 2 + $Index
    }
    $fileContent.Insert($fileLineToInsert, ($Column -join ' |'))
    $fileContent | Out-File -FilePath $FilePath
  } else {
    throw "Table with headers: '$($TableHeader -join ', ')' not found"
  }
}