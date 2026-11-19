$GrftDeepLinkPluginId = 'pubsub'
iex ((Invoke-WebRequest -UseBasicParsing -Uri "$($GrftCliRawBase.TrimEnd('/'))/plugin/invoke.ps1").Content)
