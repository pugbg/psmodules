@{
    Name                 = 'TestConfig2'
    Default              = $true
    InitializationScript = {

        Write-Warning 'Initialization'

    }
    MessageTypes         = @{
        'Error'         = {
            Write-Error -Exception $args[0]['Message'] -ErrorAction Continue
        }
        'Warning'       = {
            Write-Warning -Message $args[0]['Message']
        }
        'Informational' = {
            Write-Information -Message $args[0]['Message'] -InformationAction Continue
        }
    }
}