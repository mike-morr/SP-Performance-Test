Param (
  [Parameter(Mandatory = $True, Position = 1)]
  [int32] $fileSizeInMB,
  [switch] $noPing,
  [switch] $noTraceRoute
)

# Edit the variables below
$siteUrl = "https://devtenant.sharepoint.com/sites/teamtest2"
$downloadPath = "/sites/teamtest2/Shared Documents/DummyFile.txt"
$uploadPath = "Shared Documents"

# Do not edit anything below this line
$filePath = "./DummyFile.txt"

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

New-LargeFile -FileSize (1024 * $fileSizeInMB * 1000) # Creates file at specified size

Connect-PnPOnline $siteUrl -UseWebLogin
Write-Host "`nStarted at $(Get-Date)"
Write-Host "`nUploading dummy file to $siteUrl"
$time = Measure-Command { Add-PnPFile -Folder $uploadPath -Path $filePath }
"{0} seconds" -f $time.TotalSeconds
"{0:N2} Mbit/sec" -f (($fileSizeInMB / ($time.TotalSeconds)) * 8)

Write-Host "`nDownloading dummy file from $siteUrl"
$time = Measure-Command { Get-PnpFile -Url $downloadPath -AsString | Out-Null }
"{0} seconds" -f $time.TotalSeconds
"{0:N2} Mbit/sec" -f (($fileSizeInMB / ($time.TotalSeconds)) * 8)

if (-not $noPing) {
  $hostName = New-Object Uri($siteUrl)
  Write-Host "`nPinging $siteUrl"
  try {
    Test-Connection $hostName.Host -Count 10 -Delay 3  
  }
  catch {
    Write-Host "Unable to communicate over ICMP with $($hostName.Host)"
  }
}

if (-not $noTraceRoute) {
  Write-Host "`nTracing route to $siteUrl"
  $hosts = Test-NetConnection $hostName.Host -TraceRoute | Select-Object -ExpandProperty TraceRoute
  Write-Host "$($hosts.Count) hops total, getting ping results for each one."
  foreach ($item in $hosts) { 
    if ($item -eq "0.0.0.0") { continue }
    $resolvedHosts = Resolve-DnsName $item -type PTR -ErrorAction SilentlyContinue | Select-Object NameHost
    foreach ($resolvedHost in $resolvedHosts) {
      try {
        $ping = Test-Connection $resolvedHost.NameHost -Count 1 -ErrorAction Stop | Select-Object ResponseTime
        Write-Host "$($resolvedHost.NameHost) responded in $($ping.ResponseTime) milliseconds."
      }
      catch {
        Write-Host "$($resolvedHost.NameHost) did not respond."
      }
    }
  }
}