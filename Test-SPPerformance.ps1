$filePath = "./DummyFile.txt"
$siteUrl = "http://sp/sites/test"
$docLib = "Documents"

Add-Type -Path .\2013Client\Microsoft.SharePoint.Client.dll -ErrorAction Stop
Add-Type -Path .\2013Client\Microsoft.SharePoint.Client.Runtime.dll  -ErrorAction Stop

function New-LargeFile {
  Param ([string] $fileSize) # Specified as bytes
  $path = $filePath
  if (Test-Path $path) {
    Remove-Item $path
  }
  $file = [IO.File]::Create($filePath)
  $file.SetLength($fileSize)
  $file.Close()
}

New-LargeFile -FileSize (1024 * 100000) # Creates 100MB File

$creds = Get-Credential -Message "Enter your on-premises domain credentials in DOMAIN\USER format."

$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
$clientContext.Credentials = $creds
$clientContext.RequestTimeout = -1


$list = $clientContext.Web.Lists.GetByTitle($docLib)
$clientContext.Load($list)
$clientContext.ExecuteQuery()

$fileStream = New-Object IO.FileStream($filePath, [System.IO.FileMode]::Open)
$fileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
$fileCreationInfo.Overwrite = $true
$fileCreationInfo.ContentStream = $fileStream
$fileCreationInfo.Url = "DummyFile.txt"

$upload = $list.RootFolder.Files.Add($fileCreationInfo)
$clientContext.Load($upload)

Write-Host "`nUploading dummy file to $siteUrl"
$time = Measure-Command { $clientContext.ExecuteQuery() }
"{0} seconds" -f $time.TotalSeconds
"{0:N2} Mbit/sec" -f ((100/($time.TotalSeconds))*8)

$fileStream.Dispose()

# $clientContext.Load($list.RootFolder)
# $clientContext.ExecuteQuery()

$file = $list.RootFolder.Files.GetByUrl("DummyFile.txt");
$clientContext.Load($file)
$clientContext.ExecuteQuery()

$file.OpenBinaryStream() | Out-Null

Write-Host "`nDownloading dummy file from $siteUrl"
$time = Measure-Command { $clientContext.ExecuteQuery() }
"{0} seconds" -f $time.TotalSeconds
"{0:N2} Mbit/sec" -f ((100/($time.TotalSeconds))*8)

$hostName = New-Object Uri($siteUrl)
Write-Host "`nPinging $siteUrl"
Test-Connection $hostName.Host -Count 10 -Delay 3

Write-Host "`nTracing route to $siteUrl"
$hosts = Test-NetConnection $hostName.Host -TraceRoute | Select-Object -ExpandProperty TraceRoute
Write-Host "$($hosts.Count) hops total, getting ping results for each one."
foreach ($item in $hosts) 
{ 
  $resolvedHosts = Resolve-DnsName $item -type PTR -ErrorAction SilentlyContinue | Select-Object NameHost
  foreach ($resolvedHost in $resolvedHosts)
  {
    try
    {
      $ping = Test-Connection $resolvedHost.NameHost -Count 1 -ErrorAction Stop | Select-Object ResponseTime
      Write-Host "$($resolvedHost.NameHost) responded in $($ping.ResponseTime) milliseconds."
    }
    catch
    {
      Write-Host "$($resolvedHost.NameHost) did not respond."
    }
  }
}