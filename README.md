# Test SharePoint Performance

This repo contains 2 basic performance scripts for collecting performance data
from both SharePoint On-Premises and SharePoint Online.

## Prerequisites

* Test-SPPerformance
  * No Prerequisites
* Test-SPOPerformance
  * [SharePoint Online Management Shell](https://www.microsoft.com/en-us/download/details.aspx?id=35588)
  * [PnP Cmdlets](https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps)

## Features

* Creates a dummy file of the specified size
* Uploads the dummy file to SharePoint
* Downloads the dummy file from SharePoint
* Times the upload and download
* Gives an estimate on bandwidth used
* Ping and Traceroute to SharePoint

## Compatibility

* Test-SPPerformance
  * Works with On-Premises or D/ITAR
* Test-SPOPerformance
  * Works with SPO including ADFS

## Getting Started

You can either clone the repo or download a .zip file using the "Clone or Download" button
at the top of this page.

Once you have the scripts downloaded, you will need to edit the variables at the top of the
scripts using the same format as the sample variables provided.

Next, run the script specifying the fileSize in MB and optional parameters if needed

## Examples

```Test-SPOPerformance -fileSizeInMB 100```

You can skip the ping and trace route as well

```Test-SPOPerformance -fileSizeInMB 100 -noPing -noTraceRoute```
