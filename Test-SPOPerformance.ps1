$filePath = "./DummyFile.txt"
$siteUrl = "https://devtenant.sharepoint.com/sites/teamtest2"
$downloadPath = "/sites/teamtest2/Shared Documents/DummyFile.txt"
$uploadPath = "Shared Documents"

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

Connect-PnPOnline $siteUrl -UseWebLogin
Write-Host "`nStarted at $(Get-Date)"
Write-Host "`nUploading dummy file to $siteUrl"
$time = Measure-Command { Add-PnPFile -Folder $uploadPath -Path $filePath }
"{0} seconds" -f $time.TotalSeconds
"{0:N2} Mbit/sec" -f ((100/($time.TotalSeconds))*8)

Write-Host "`nDownloading dummy file from $siteUrl"
$time = Measure-Command { Get-PnpFile -Url $downloadPath -AsString | Out-Null }
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
  if ($item -eq "0.0.0.0") { continue }
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