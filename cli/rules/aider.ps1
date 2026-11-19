$GrftDeepLinkRulesIde = 'aider'
iex ((Invoke-WebRequest -UseBasicParsing -Uri "$($GrftCliRawBase.TrimEnd('/'))/rules/invoke.ps1").Content)
