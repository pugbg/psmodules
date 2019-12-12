function SetupContext 
{
    $result = @{
        ModuleName   = 'HtmlHelper'
        ModuleFolder = Split-Path -Path $PSScriptRoot -Parent -ErrorAction Stop
    }

    import-module -FullyQualifiedName $result['ModuleFolder'] -Force -ErrorAction Stop

    $result
}

describe "htmldoc" {
    $ModuleTestingContext = SetupContext

    context "empty htmldoc" {

        it "empty htmldoc should not fail" {
            $result = htmldoc {

            }
    
            $result | should -BeOfType 'String'
        }

    }

    context "htmldoc with table" {
        it "htmldoc with empty table should not fail" {
            $result = htmldoc {
                table { }
            }
    
            $result | should -BeOfType 'String'
        }
    }

}

describe "table" {
    $ModuleTestingContext = SetupContext

    context "empty table" {
        it "empty table should not fail" {
            $result = table {
    
            }
        
            $result | should -BeOfType 'String'
        }
    }

    context "table with row" {
        it "table with empty row should not fail" {
            $result = htmldoc {
                table {
                    table-row { }
                }
            }
    
            $result | should -BeOfType 'String'
        }
    }

    context "table with column" {
        it "table with empty column should not fail" {
            $result = htmldoc {
                table {
                    table-column 'Column1' @{ } { }
                }
            }
    
            $result | should -BeOfType 'String'
        }
    }

}

describe "table-column" {
    $ModuleTestingContext = SetupContext

    context "empty table-column" {
        it "empty table-column should not fail" {
            $result = table-column 'Column1' @{ } {
    
            }
        
            $result | should -BeOfType 'String'
        }
    }

    context "table-column with row" {
        it "table-column with empty row should not fail" {
            $result = table-column 'Column1' @{ } {
                table-row { }
            }
        
            $result | should -BeOfType 'String'
        }
    }

    context "table-column with paragraph" {
        it "table-column with empty paragraph should not fail" {
            $result = table-column 'Column1' @{ } {
                paragraph @{ } { }
            }
        
            $result | should -BeOfType 'String'
        }
    }
}

describe "table-row" {
    $ModuleTestingContext = SetupContext

    context "empty table-row" {
        it "empty table-row should not fail" {
            table-row { } | should -BeOfType 'String'
        }
    }

    context "table-row with column" {
        it "table-row with empty column should not fail" {
            table-row {
                table-column 'Column1' @{ } {
                    
                } 
            } | should -BeOfType 'String'
        }
    }

    context "table-row with paragraph" {
        it "table-row with empty paragraph should not fail" { 
            paragraph @{ } { } | should -BeOfType 'String'
        }
    }
}

describe "paragraph" {
    $ModuleTestingContext = SetupContext

    context "empty paragraph" {
        it "empty paragraph should not fail" {
            paragraph @{ } { } | should -BeOfType 'String'
        }
    }

    context "paragraph with string" {
        it "paragraph with string should not fail" {
            paragraph @{ } { 'Some string here' } | should -BeOfType 'String'
        }
    }
}