<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 2d589791-b42a-468d-951a-11e1bb2de7af

.AUTHOR oaltawil@microsoft.com

#>

#Requires -psedition Desktop

<#
.NOTES
****************************************************************************************************************
This sample is not supported under any Microsoft standard support program or service. This sample
is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties
including, without limitation, any implied warranties of merchantability or of fitness for a particular
purpose. The entire risk arising out of the use or performance of this sample and documentation
remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation,
production, or delivery of this sample be liable for any damages whatsoever (including, without limitation,
damages for loss of business profits, business interruption, loss of business information, or other
pecuniary loss) arising out of the use of or inability to use this sample or documentation, even
if Microsoft has been advised of the possibility of such damages.
****************************************************************************************************************

.SYNOPSIS
This sample script creates Prestaged Content files (.pkgx) from Applications, Boot Images, (Software Update) Deployment Packages, Driver Packages, Operating System Images, Operating System Installers, and Packages that are located on a source Distribution Point.

.DESCRIPTION
The script requires the SMS Site Code, the FQDN of a source Distribution Point that contains the desired Applications, Boot Images, (Software Update) Deployment Packages, etc. and the full path to a destination folder where all prestaged content files (.pkgx) will be created. 

The script also requires the desired Content Type and the Package Id's of the Items that belong to that Content Type.

The script supports only one Content Type from the following list:
 - Application
 - BootImage
 - DeploymentPackage
 - DriverPackage
 - OperatingSystemImage
 - OperatingSystemInstaller
 - Package

The user must also specify the Package ID's of Applications, Boot Images, (Software Update) Deployment Packages, etc. that belong to that specific Content Type.

.PARAMETER SiteCode
Configuration Manager Site Code.

.PARAMETER SourceDistributionPoint
FQDN (Fully-Qualified Domain Name) of the source Distribution Point that contains the desired Applications, Boot Images, etc.

.PARAMETER OutputFolderPath
Full path to the folder where the prestaged content files (.pkgx) will be created. The script will create the output folder, if it does not exist, and will create subfolders for each content type.

.PARAMETER ContentType
One of the supported CM content types: 
- Application
- BootImage
- DeploymentPackage
- DriverPackage
- OperatingSystemImage
- OperatingSystemInstaller
- Package

.PARAMETER PackageIds
A list of the Package IDs of the desired CM Items that being to the specified Content Type

.PARAMETER InputFilePath
** This parameter is currently ignored ** The full path to a comma-separated value file with 2 column headers: ContentType and PackageId

Example:
ContentType, PackageId
Application, PTS0000A
Application, PTS0000C
BootImage, PTS00003
Package, PTS00001

.EXAMPLE
Generate Prestaged Content Files (.pkgx) from the Applications that have the specified Package IDs and that are located on the Distribution Point "MCM-01.poltis.ca" and save them to the Output Folder "E:\PrestagedContent"

Export-CMPrestagedContent -SiteCode PTS -SourceDistributionPoint MCM-01.poltis.ca -OutputFolderPath E:\PrestagedContent -ContentType Application -PackageIds PTS00009, PTS0000C, PTS0000D

#>

[CmdletBinding(DefaultParameterSetName = 'ContentTypePackageIds')]
param (
    [Parameter(Position = 0, ParameterSetName='ContentTypePackageIds', Mandatory=$true)]
    [Parameter(Position = 0, ParameterSetName='InputFilePath', Mandatory=$true)]
    [String]
    $SiteCode,

    [Parameter(Position = 1, ParameterSetName='ContentTypePackageIds', Mandatory=$true)]
    [Parameter(Position = 1, ParameterSetName='InputFilePath', Mandatory=$true)]
    [String]
    $SourceDistributionPoint,

    [Parameter(Position = 2, ParameterSetName='ContentTypePackageIds', Mandatory=$true)]
    [Parameter(Position = 2, ParameterSetName='InputFilePath', Mandatory=$true)]
    [String]
    $OutputFolderPath,

    [Parameter(Position = 3, ParameterSetName='ContentTypePackageIds', Mandatory=$true)]
    [ValidateSet("Application", "BootImage", "DeploymentPackage", "DriverPackage", "OperatingSystemImage", "OperatingSystemInstaller", "Package")]
    [String]
    $ContentType,

    [Parameter(Position = 4, ParameterSetName='ContentTypePackageIds', Mandatory=$false)]
    [String[]]
    $PackageIds,

    [Parameter(Position = 3, ParameterSetName='InputFilePath', Mandatory=$true)]
    [String]
    $InputFilePath

)

$ErrorActionPreference = 'Continue'

# Import the Configuration Manager PowerShell Module
Import-Module -Name "$ENV:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1" -ErrorAction Stop

# Set the current location to the SMS Site Code PowerShell Drive
Set-Location "$($SiteCode):"

# Generate the name of the subfolder for each Content Type, e.g. Applications, BootImages, etc.
$ContentTypeDirectory = Join-Path $OutputFolderPath $($ContentType + "s")

# Create a new subfolder for each Content Type
New-Item -Path $ContentTypeDirectory -ItemType Directory -Force | Out-Null

switch ($ContentType) {

    "Application" {

        $AllApplications = Get-CMApplication

        # Retrieve all Applications with content and matching Package Ids and generate the Prestaged Content File (.pkgx) for each Application
        foreach ($PackageId in $PackageIds) {

            $Application = $AllApplications | Where-Object {($_.HasContent -eq $true) -and ($_.PackageId -eq $PackageId)}

            if (-not $Application) {

                Write-Error "Failed to find the Application with Package Id $PackageId"

            }
            else {
            
                Publish-CMPrestageContent -Application $Application -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
            
            }
        
        }

    }

    "BootImage" {

        $AllBootImages = Get-CMBootImage

        # Retrieve all Boot Images with matching Package IDs and export the Prestaged Content File (.pkgx) for each Boot Image
        foreach ($PackageId in $PackageIds) {

            $BootImage = $AllBootImages | Where-Object {$_.PackageId -eq $PackageId}

            if (-not $BootImage) {

                Write-Error "Failed to find the Boot Image with Package Id $PackageId"

            }
            else {

                Publish-CMPrestageContent -BootImage $BootImage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
            
            }
        }

    }

    "DeploymentPackage" {

        $AllDeploymentPackages = Get-CMSoftwareUpdateDeploymentPackage

        # Retrieve all (Software Update) Deployment packages with matching Package IDs and export the Prestaged Content File (.pkgx) for each Deployment Package
        foreach ($PackageId in $PackageIds) {

            $DeploymentPackage = $AllDeploymentPackages | Where-Object {$_.PackageId -eq $PackageId}

            if (-not $DeploymentPackage) {

                Write-Error "Failed to find the (Software Update) Deployment Package with Package Id $PackageId"

            }
            else {

                Publish-CMPrestageContent -DeploymentPackage $DeploymentPackage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
            
            }
        }
        
    }

    "DriverPackage" {

        $AllDriverPackages = Get-CMDriverPackage

        # Retrieve all Driver Packages with matching Package IDs and export the Prestaged Content File (.pkgx) for each Driver Package
        foreach ($PackageId in $PackageIds) {

            $DriverPackage = $AllDriverPackages | Where-Object {$_.PackageId -eq $PackageId}

            if (-not $DriverPackage) {

                Write-Error "Failed to find the Driver Package with Package Id $PackageId"

            }
            else {
                
                Publish-CMPrestageContent -DriverPackage $DriverPackage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
            }

        }

    }

    "OperatingSystemImage" {
        
        $AllOperatingSystemImages = Get-CMOperatingSystemImage

        # Retrieve all Operating System Images with matching Package IDs and export the Prestaged Content File (.pkgx) for each Operating System Image
        foreach ($PackageId in $PackageIds) {

            $OperatingSystemImage = $AllOperatingSystemImages | Where-Object {$_.PackageId -eq $PackageId}

            if (-not $OperatingSystemImage) {

                Write-Error "Failed to find the Operating System Image with Package Id $PackageId"

            }
            else {

                Publish-CMPrestageContent -OperatingSystemImage $OperatingSystemImage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
            
            }
        
        }
    
    }

    "OperatingSystemInstaller" {

        $AllOperatingSystemInstallers = Get-CMOperatingSystemInstaller

        # Retrieve all Operating System Installers with matching Package IDs and export the Prestaged Content File (.pkgx) for each Operating System Installer
        foreach ($PackageId in $PackageIds) {

            $OperatingSystemInstaller = $AllOperatingSystemInstallers | Where-Object {$_.PackageId -eq $PackageId}

            if (-not $OperatingSystemInstaller) {

                Write-Error "Failed to find the Operating System Installer with Package Id $PackageId"

            }
            else {
            
                Publish-CMPrestageContent -OperatingSystemInstaller $OperatingSystemInstaller -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
        
            }
        
        }

    }

    "Package" {
    
        $AllPackages = Get-CMPackage

        # Retrieve all (Legacy Software Distribution) Packages with matching Package IDs and export the Prestaged Content File (.pkgx) for each Package
        foreach ($PackageId in $PackageIds) {

            $Package = $AllPackages | Where-Object {$_.PackageId -eq $PackageId}

            if (-not $Package) {

                Write-Error "Failed to find the (Legacy Software Distribution) Package with Package Id $PackageId"

            }
            else {
            
                Publish-CMPrestageContent -Package $Package -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
            
            }
        
        }
        
    }

}

