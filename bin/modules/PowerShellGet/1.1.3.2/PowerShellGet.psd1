@{
RootModule = 'PSModule.psm1'
ModuleVersion = '1.1.3.2'
GUID = '1d73a601-4a6c-43c5-ba3f-619b18bbb404'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = 'PowerShell module with commands for discovering, installing, updating and publishing the PowerShell artifacts like Modules, DSC Resources, Role Capabilities and Scripts.'
PowerShellVersion = '3.0'
FormatsToProcess = 'PSGet.Format.ps1xml'
FunctionsToExport = @('Install-Module',
                      'Find-Module',
                      'Save-Module',
                      'Update-Module',
                      'Publish-Module', 
                      'Get-InstalledModule',
                      'Uninstall-Module',
                      'Find-Command', 
                      'Find-DscResource', 
                      'Find-RoleCapability',
                      'Install-Script',
                      'Find-Script',
                      'Save-Script',
                      'Update-Script',
                      'Publish-Script', 
                      'Get-InstalledScript',
                      'Uninstall-Script',
                      'Test-ScriptFileInfo',
                      'New-ScriptFileInfo',
                      'Update-ScriptFileInfo',
                      'Get-PSRepository',
                      'Set-PSRepository',                      
                      'Register-PSRepository',
                      'Unregister-PSRepository',
                      'Update-ModuleManifest')
VariablesToExport = "*"
AliasesToExport = @('inmo',
                    'fimo',
                    'upmo',
                    'pumo')
FileList = @('PSModule.psm1',
             'PSGet.Format.ps1xml',
             'PSGet.Resource.psd1')
RequiredModules = @(@{ModuleName='PackageManagement';ModuleVersion='1.0.0.1'})
PrivateData = @{
                "PackageManagementProviders" = 'PSModule.psm1'
                "SupportedPowerShellGetFormatVersions" = @('1.x')
    PSData = @{
        Tags = @('Packagemanagement',
                 'Provider',
                 'PSEdition_Desktop',
                 'PSEdition_Core',
                 'Linux',
                 'Mac')
        ProjectUri = 'https://go.microsoft.com/fwlink/?LinkId=828955'
        LicenseUri = 'https://go.microsoft.com/fwlink/?LinkId=829061'
        ReleaseNotes = @'
## 1.1.3.2
* Disabled PowerShellGet Telemetry on PS Core as PowerShell Telemetry APIs got removed in PowerShell Core beta builds. (#153)
* Fixed for DateTime format serialization issue. (#141)
* Update-ModuleManifest should add ExternalModuleDependencies value as a collection. (#129)

## 1.1.3.1

New features
* Added `PrivateData` field to ScriptFileInfo. (#119)

Bug fixes
* Fixed Add-Type issue in v6.0.0-beta.1 release of PowerShellCore. (#125, #124)
* Install-Script -Scope CurrentUser PATH changes should not require a reboot for new PS processes. (#124)
    - Made changes to broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon.
* Changed `Get-EnvironmentVariable` to get the unexpanded version of `%path%`. (#117)
* Refactor credential parameter propagation to sub-functions. (#104)
* Added credential parameter to subsequent calls of `Publish-Module/Script`. (#93)
    - This is needed when a module is published that has the RequiredModules attribute in the manifest on a repository that does not have anonymous access because the required module lookups will fail.

## 1.1.2.0

Bug fixes
* Renamed `PublishModuleIsNotSupportedOnNanoServer` errorid to `PublishModuleIsNotSupportedOnPowerShellCoreEdition`. (#44)
    - Also renamed `PublishScriptIsNotSupportedOnNanoServer` to `PublishScriptIsNotSupportedOnPowerShellCoreEdition`.
* Fixed an issue in `Update-Module` and `Update-Script` cmdlets to show proper version of current item being updated in `Confirm`/`WhatIf` message. (#44)
* Updated `Test-ModuleInstalled` function to return single module instead of multiple modules. (#44)
* Updated `ModuleCommandAlreadyAvailable` error message to include all conflicting commands instead of one.  (#44)
    - Corresponding changes to collect the complete set of conflicting commands from the being installed.
    - Also ensured that conflicting commands from PSModule.psm1 are ignored in the command collision analysis as Get-Command includes the commands from current local scope as well.

* Fixed '[Test-ScriptFileInfo] Fails on *NIX newlines (LF vs. CRLF)' (#18)


## 1.1.1.0

Bug fixes
* Fixed 'Update-Module fails with `ModuleAuthenticodeSignature` error for modules with signed PSD1'. (#12) (#8)
* Fixed 'Properties of `AdditionalMetadata` are case-sensitive'. #7
* Changed `ErrorAction` to `Ignore` for few cmdlet usages as they should not show up in ErrorVariable.
    - For example, error returned by `Get-Command Test-FileCatalog` should be ignored.


## 1.1.0.0

* Initial release from GitHub.
* PowerShellCore support.
* Security enhancements including the enforcement of catalog-signed modules during installation.
* Authenticated Repository support.
* Proxy Authentication support.
* Responses to a number of user requests and issues.
'@
    }
}

HelpInfoURI = 'http://go.microsoft.com/fwlink/?LinkId=393271'
}

# SIG # Begin signature block
# MIIasAYJKoZIhvcNAQcCoIIaoTCCGp0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8qzIUuX/qlkxniOdvkwI0b9e
# DWCgghWDMIIEwzCCA6ugAwIBAgITMwAAALbYAJUMg2JtoQAAAAAAtjANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODQ0
# WhcNMTgwOTA3MTc1ODQ0WjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OjMxQzUtMzBCQS03QzkxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlitSnGveWTDN
# e1jrQZjYpA9N4OXmCTtz/jy98iVz0ro/f2ELzjwkrzQycPykmlVlOxzzzaSIBmqK
# HiWJXU9m6mU0WS8/O8GV2U8d9PA057wJ/6+3ptVocqSANSNpXip5qKRl5P1Wac0Z
# 5oJ1NOXPnu1J4slB7ssE2ifDwS+0kHkTU3FdKeh8dAoC7GoQU0aFQdPFikvh7YRa
# gwPzzPVs96zCJdIY4gPGqdi8ajX3xrJI4th7QdO98fpj8f1CBJtlELMDiaMwUu0e
# 2VLTFE1sl1cyer4afcTuf+ENNRyiH+LJ5nHRK3/zkTYpjv8G/tfp3swk2ha9tsPP
# ddCge17XYQIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFOjzQTSj/oQgLDnBEUwqsxz4
# 7wKyMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAGotNN2Ff2yTVo4VKnHCmG+PxMuqhs1ke1JE5bQu3bGRgIWX
# riEZvWVqgDUihF4GmcPRHatBE9qtM5ewhDuSIGBf/5rqskW00Q4Kgb7mDtx/sOV7
# wNXJ0HjFgyNRqVDVxVE6uZ8bCTi+TjhfuIBZj85UbdfG/qtPkQkzgmaK83dgLPEH
# T8Je8gd7orVPNkI3lqkQbQ8X4ZISiP+heRsPYtlgeMGvnle5ssGzB2O5Ozt527Fa
# Ztpxi32uN1Qk8hV7xM+Z4ujOGqJFxVQfCGlMU0tXTvaRNoNpKWSp2fjYHyasLXAU
# y7ZhZHq7qWAilzmqCFYZIDPJmjUtm1/hqhqqqxQwggTtMIID1aADAgECAhMzAAAB
# QJap7nBW/swHAAEAAAFAMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBMB4XDTE2MDgxODIwMTcxN1oXDTE3MTEwMjIwMTcxN1owgYMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# HjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBANtLi+kDal/IG10KBTnk1Q6S0MThi+ikDQUZWMA81ynd
# ibdobkuffryavVSGOanxODUW5h2s+65r3Akw77ge32z4SppVl0jII4mzWSc0vZUx
# R5wPzkA1Mjf+6fNPpBqks3m8gJs/JJjE0W/Vf+dDjeTc8tLmrmbtBDohlKZX3APb
# LMYb/ys5qF2/Vf7dSd9UBZSrM9+kfTGmTb1WzxYxaD+Eaxxt8+7VMIruZRuetwgc
# KX6TvfJ9QnY4ItR7fPS4uXGew5T0goY1gqZ0vQIz+lSGhaMlvqqJXuI5XyZBmBre
# ueZGhXi7UTICR+zk+R+9BFF15hKbduuFlxQiCqET92ECAwEAAaOCAWEwggFdMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSc5ehtgleuNyTe6l6pxF+QHc7Z
# ezBSBgNVHREESzBJpEcwRTENMAsGA1UECxMETU9QUjE0MDIGA1UEBRMrMjI5ODAz
# K2Y3ODViMWMwLTVkOWYtNDMxNi04ZDZhLTc0YWU2NDJkZGUxYzAfBgNVHSMEGDAW
# gBTLEejK0rQWWAHJNy4zFha5TJoKHzBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNDb2RTaWdQQ0Ff
# MDgtMzEtMjAxMC5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BDQV8wOC0z
# MS0yMDEwLmNydDANBgkqhkiG9w0BAQUFAAOCAQEAa+RW49cTHSBA+W3p3k7bXR7G
# bCaj9+UJgAz/V+G01Nn5XEjhBn/CpFS4lnr1jcmDEwxxv/j8uy7MFXPzAGtOJar0
# xApylFKfd00pkygIMRbZ3250q8ToThWxmQVEThpJSSysee6/hU+EbkfvvtjSi0lp
# DimD9aW9oxshraKlPpAgnPWfEj16WXVk79qjhYQyEgICamR3AaY5mLPuoihJbKwk
# Mig+qItmLPsC2IMvI5KR91dl/6TV6VEIlPbW/cDVwCBF/UNJT3nuZBl/YE7ixMpT
# Th/7WpENW80kg3xz6MlCdxJfMSbJsM5TimFU98KNcpnxxbYdfqqQhAQ6l3mtYDCC
# BbwwggOkoAMCAQICCmEzJhoAAAAAADEwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmS
# JomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UE
# AxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTEwMDgz
# MTIyMTkzMloXDTIwMDgzMTIyMjkzMloweTELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQ
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCycllcGTBkvx2aYCAg
# Qpl2U2w+G9ZvzMvx6mv+lxYQ4N86dIMaty+gMuz/3sJCTiPVcgDbNVcKicquIEn0
# 8GisTUuNpb15S3GbRwfa/SXfnXWIz6pzRH/XgdvzvfI2pMlcRdyvrT3gKGiXGqel
# cnNW8ReU5P01lHKg1nZfHndFg4U4FtBzWwW6Z1KNpbJpL9oZC/6SdCnidi9U3RQw
# WfjSjWL9y8lfRjFQuScT5EAwz3IpECgixzdOPaAyPZDNoTgGhVxOVoIoKgUyt0vX
# T2Pn0i1i8UU956wIAPZGoZ7RW4wmU+h6qkryRs83PDietHdcpReejcsRj1Y8wawJ
# XwPTAgMBAAGjggFeMIIBWjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTLEejK
# 0rQWWAHJNy4zFha5TJoKHzALBgNVHQ8EBAMCAYYwEgYJKwYBBAGCNxUBBAUCAwEA
# ATAjBgkrBgEEAYI3FQIEFgQU/dExTtMmipXhmGA7qDFvpjy82C0wGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwHwYDVR0jBBgwFoAUDqyCYEBWJ5flJRP8KuEKU5VZ
# 5KQwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUFBwEB
# BEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwDQYJKoZIhvcNAQEFBQADggIBAFk5
# Pn8mRq/rb0CxMrVq6w4vbqhJ9+tfde1MOy3XQ60L/svpLTGjI8x8UJiAIV2sPS9M
# uqKoVpzjcLu4tPh5tUly9z7qQX/K4QwXaculnCAt+gtQxFbNLeNK0rxw56gNogOl
# VuC4iktX8pVCnPHz7+7jhh80PLhWmvBTI4UqpIIck+KUBx3y4k74jKHK6BOlkU7I
# G9KPcpUqcW2bGvgc8FPWZ8wi/1wdzaKMvSeyeWNWRKJRzfnpo1hW3ZsCRUQvX/Ta
# rtSCMm78pJUT5Otp56miLL7IKxAOZY6Z2/Wi+hImCWU4lPF6H0q70eFW6NB4lhhc
# yTUWX92THUmOLb6tNEQc7hAVGgBd3TVbIc6YxwnuhQ6MT20OE049fClInHLR82zK
# wexwo1eSV32UjaAbSANa98+jZwp0pTbtLS8XyOZyNxL0b7E8Z4L5UrKNMxZlHg6K
# 3RDeZPRvzkbU0xfpecQEtNP7LN8fip6sCvsTJ0Ct5PnhqX9GuwdgR2VgQE6wQuxO
# 7bN2edgKNAltHIAxH+IOVN3lofvlRxCtZJj/UBYufL8FIXrilUEnacOTj5XJjdib
# Ia4NXJzwoq6GaIMMai27dmsAHZat8hZ79haDJLmIz2qoRzEvmtzjcT3XAH5iR9HO
# iMm4GPoOco3Boz2vAkBq/2mbluIQqBC0N1AI1sM9MIIGBzCCA++gAwIBAgIKYRZo
# NAAAAAAAHDANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZImiZPyLGQBGRYDY29tMRkw
# FwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDcwNDAzMTI1MzA5WhcNMjEwNDAz
# MTMwMzA5WjB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCfoWyx39tIkip8ay4Z4b3i48WZUSNQrc7dGE4kD+7R
# p9FMrXQwIBHrB9VUlRVJlBtCkq6YXDAm2gBr6Hu97IkHD/cOBJjwicwfyzMkh53y
# 9GccLPx754gd6udOo6HBI1PKjfpFzwnQXq/QsEIEovmmbJNn1yjcRlOwhtDlKEYu
# J6yGT1VSDOQDLPtqkJAwbofzWTCd+n7Wl7PoIZd++NIT8wi3U21StEWQn0gASkdm
# EScpZqiX5NMGgUqi+YSnEUcUCYKfhO1VeP4Bmh1QCIUAEDBG7bfeI0a7xC1Un68e
# eEExd8yb3zuDk6FhArUdDbH895uyAc4iS1T/+QXDwiALAgMBAAGjggGrMIIBpzAP
# BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQjNPjZUkZwCu1A+3b7syuwwzWzDzAL
# BgNVHQ8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwgZgGA1UdIwSBkDCBjYAUDqyC
# YEBWJ5flJRP8KuEKU5VZ5KShY6RhMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eYIQea0WoUqgpa1Mc1j0BxMuZTBQBgNVHR8E
# STBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsG
# AQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFJvb3RDZXJ0LmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0B
# AQUFAAOCAgEAEJeKw1wDRDbd6bStd9vOeVFNAbEudHFbbQwTq86+e4+4LtQSooxt
# YrhXAstOIBNQmd16QOJXu69YmhzhHQGGrLt48ovQ7DsB7uK+jwoFyI1I4vBTFd1P
# q5Lk541q1YDB5pTyBi+FA+mRKiQicPv2/OR4mS4N9wficLwYTp2OawpylbihOZxn
# LcVRDupiXD8WmIsgP+IHGjL5zDFKdjE9K3ILyOpwPf+FChPfwgphjvDXuBfrTot/
# xTUrXqO/67x9C0J71FNyIe4wyrt4ZVxbARcKFA7S2hSY9Ty5ZlizLS/n+YWGzFFW
# 6J1wlGysOUzU9nm/qhh6YinvopspNAZ3GmLJPR5tH4LwC8csu89Ds+X57H2146So
# dDW4TsVxIxImdgs8UoxxWkZDFLyzs7BNZ8ifQv+AeSGAnhUwZuhCEl4ayJ4iIdBD
# 6Svpu/RIzCzU2DKATCYqSCRfWupW76bemZ3KOm+9gSd0BhHudiG/m4LBJ1S2sWo9
# iaF2YbRuoROmv6pH8BJv/YoybLL+31HIjCPJZr2dHYcSZAI9La9Zj7jkIeW1sMpj
# tHhUBdRBLlCslLCleKuzoJZ1GtmShxN1Ii8yqAhuoFuMJb+g74TKIdbrHk/Jmu5J
# 4PcBZW+JC33Iacjmbuqnl84xKf8OxVtc2E0bodj6L54/LlUWa8kTo/0xggSXMIIE
# kwIBATCBkDB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSMw
# IQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQQITMwAAAUCWqe5wVv7M
# BwABAAABQDAJBgUrDgMCGgUAoIGwMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSl
# SMuv1BtSIyfhzwqqPMAhyhxG+jBQBgorBgEEAYI3AgEMMUIwQKAWgBQAUABvAHcA
# ZQByAFMAaABlAGwAbKEmgCRodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vUG93ZXJT
# aGVsbCAwDQYJKoZIhvcNAQEBBQAEggEAJEDfG/oA3NtN2YAwhHoCR2IyFmkdkSk2
# CxR90H1q2YH1EdSlpbU0u8m2ZBpHMbwh5bC1nn36VkVWxdG9zm5SAqVBZ0L+PLgA
# nGZJU42Ztaz9pxrMyz8/uEakuhLWgOQAB1STGmHqGZ3uV3vRlDpEqdTY313YzFQz
# lhMYBlgVSM5nZXCUWtImDsq4KY167MaYa3aUoniQYfPpjfcom1yUgIr9++Rhth2E
# 6OX0Q7zGzPi24sEyVEtUF1dH/5YieZJg+gxx3PH2ESlk6YBKzhMc1+SefkOOnzPA
# w0ySd8MKyTuXsPsONBGKmzGcDJ5jN84kuufmUWUpkh+ZbPnYxKjgDaGCAigwggIk
# BgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0ECEzMAAAC22ACVDINibaEAAAAAALYwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE3MDgwODE2NTM0MFowIwYJ
# KoZIhvcNAQkEMRYEFIm9XfYyAxa4KSIekIONEidZzGZqMA0GCSqGSIb3DQEBBQUA
# BIIBADTPaG8qlyeLrmo4Rpus0+I35fD24tsfSl5Fzjwak1xtY/mHweQoOBimj8jX
# uXJ/9t2z+mn9vypIPn6q6cFo4uVstxOZsJKBTbEjZYiHOoGJuB6diMYZ/MFmSxqL
# eyTz/SNAtSXM9rAs2x7LIzt4d9e3gQLVYaYqlqGR7F3SON+0/MDic/agv7v1qeFH
# XzcYyoCWYuzqv0Trnj6ctoP7QaIdcU3tfXB6i1HNsQO9S6kecIAhMftnu3BVzHOb
# KD6pAnYmPjWmRLtnBRk/wT3IxPsNnPNHpl67inkPimucsBQ0KE44I0lN+D4zAJWX
# gb2limJ/lmwxrUGdBTwgbGzXKHo=
# SIG # End signature block
