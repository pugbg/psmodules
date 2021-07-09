function SetupContext 
{
    $result = @{
        ModuleName   = 'PSMermaid'
        ModuleFolder = Split-Path -Path $PSScriptRoot -Parent -ErrorAction Stop
    }

    import-module -FullyQualifiedName $result['ModuleFolder'] -Force -ErrorAction Stop

    $result
}

describe "m-node" {
    $ModuleTestingContext = SetupContext

    context "with everything" {

        it "should return string" {
            $result = m-node -Id n1 -Attributes @{
                Name   = 'Node1'
                Shape  = 'hexagon'
                LinkTo = 'id2'
            }
    
            $result | should -BeOfType 'String'
        }

    }
}

describe "m-graph" {
    $ModuleTestingContext = SetupContext

    context "with everything" {

        it "should return string" {
            $result = m-graph -Orientation TB -classDef @{edgePath = 'stroke-width:0px' } -Body {
                m-subgraph -Id p -Attributes @{Name = 'Platform'; style = 'fill:#ccf' } -Body {
                    m-node -Id p1 -Attributes @{
                        Name               = 'Platform1'
                        InteractionLink    = 'https://google.bg'
                        InteractionTooltip = 'This is google'
                        Style              = 'fill:#F4BBFF'
                    }
                    m-node -Id p2 -Attributes @{
                        Name            = 'Platform2'
                        InteractionLink = 'https://abv.bg'
                        Style           = 'fill:#F4BBFF'
                    }
                    m-node -Id p3 -Attributes @{
                        Name  = 'Platform3'
                        Style = 'fill:#F4BBFF'
                    }
                }
                m-subgraph -Id m -Attributes @{Name = 'Mandatory' } -Body {
                    m-node -Id m1 -Attributes @{
                        Name   = 'Mandatory1'
                        LinkTo = 'p1'
                    }
                    m-node -Id m2 -Attributes @{
                        Name   = 'Mandatory2'
                        LinkTo = 'p1'
                    }
                }
                m-subgraph -Id o -Attributes @{Name = 'Optional' } -Body {
                    m-node -Id o1 -Attributes @{
                        Name   = 'Optional1'
                        LinkTo = 'p1'
                    }
                    m-node -Id o2 -Attributes @{
                        Name   = 'Optional2'
                        LinkTo = 'p1'
                    }
                }
            } 
    
            $result | should -BeOfType 'String'
        }
    }
}