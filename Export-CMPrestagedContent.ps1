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
This sample script creates Prestaged Content files (.pkgx) from all Applications, Boot Images, (Software Update) Deployment Packages, Driver Packages, Operating System Images, Operating System Installers, and Packages located on a source Distribution Point.

.DESCRIPTION
The script requires the FQDN of a source Distribution Point that contains the desired Applications, Boot Images, etc. and the full path to a destination folder where all prestaged content files (.pkgx) will be created. 

The script creates prestage content files (.pkgx) from all of the following CM content types:
- Application
- BootImage
- DeploymentPackage
- DriverPackage
- OperatingSystemImage
- OperatingSystemInstaller
- Package

The user can optionally specify only one of the above content types to export, instead of all of them.

.PARAMETER SiteCode
Configuration Manager Site Code.

.PARAMETER SourceDistributionPoint
FQDN (Fully-Qualified Domain Name) of the source Distribution Point that contains the desired Applications, Boot Images, etc.

.PARAMETER OutputFolderPath
Full path to the folder where the prestaged content files (.pkgx) will be created. The script will create the output folder, if it does not exist, and will create subfolders for each content type.

.PARAMETER ContentType
Optional parameter to restrict the script to only one of the supported CM content types: Application, BootImage, DeploymentPackage, DriverPackage, OperatingSystemImage, OperatingSystemInstaller, Package.

.EXAMPLE
Generate Prestaged Content Files (.pkgx) from all supported CM Content Types (Applications, Boot Images, Software Update Deployment Packages, etc.) that are located on the Distribution Point "MCM-01.poltis.ca" and save them to the Output Folder "E:\PrestagedContent"

Export-CMPrestagedContent -SiteCode "PTS" -SourceDistributionPoint "MCM-01.poltis.ca" -OutputFolderPath "E:\PrestagedContent"

.EXAMPLE
Generate Prestaged Content Files (.pkgx) from all Applications that are located on the Distribution Point "MCM-01.poltis.ca" and save them to the Output Folder "E:\PrestagedContent"

Export-CMPrestagedContent -SiteCode "PTS" -SourceDistributionPoint "MCM-01.poltis.ca" -OutputFolderPath "E:\PrestagedContent" -ContentType "Application"

#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory=$true)]
    [String]
    $SiteCode,

    [Parameter(Position = 1, Mandatory=$true)]
    [String]
    $SourceDistributionPoint,

    [Parameter(Position = 2, Mandatory=$true)]
    [String]
    $OutputFolderPath,

    [Parameter(Position = 3, Mandatory=$false)]
    [ValidateSet("Application", "BootImage", "DeploymentPackage", "DriverPackage", "OperatingSystemImage", "OperatingSystemInstaller", "Package")]
    [String]
    $ContentType
)

# Import the Configuration Manager PowerShell Module
Import-Module -Name "$ENV:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"

# Set the current location to the SMS Site Code PowerShell Drive
Set-Location "$($SiteCode):"

# If the user specified the desired Content Type, then the script will export only that Content Type
if ($ContentType) {

    $ContentTypes = @($ContentType)

}
# Otherwise, the script will export all supported CM Content Types
else {

    $ContentTypes = @(
        "Application"
        "BootImage"
        "DeploymentPackage"
        "DriverPackage"
        "OperatingSystemImage"
        "OperatingSystemInstaller"
        "Package"
    )

}

# Iterate through each Content Type in the $ContentTypes array
foreach ($ContentType in $ContentTypes) {

    # Generate the name of the subfolder for each Content Type, e.g. Applications, BootImages, etc.
    $ContentTypeDirectory = Join-Path $OutputFolderPath $($ContentType + "s")

    # Create a new subfolder for each Content Type
    New-Item -Path $ContentTypeDirectory -ItemType Directory -Force | Out-Null

    switch ($ContentType) {

        "Application" {
            # Retrieve all Applications that have content and export the Prestaged Content File (.pkgx) for each Application
            Get-CMApplication -Fast | Where-Object HasContent -eq $true | ForEach-Object {Publish-CMPrestageContent -ApplicationName "$($_.LocalizedDisplayName)" -DisableWildcardHandling -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.LocalizedDisplayName + ".pkgx"))}

        }

        "BootImage" {
            # Retrieve all Boot Images and export the Prestaged Content File (.pkgx) for each Boot Image
            Get-CMBootImage  | ForEach-Object {Publish-CMPrestageContent -BootImage $_ -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.Name + ".pkgx"))}

        }

        "DeploymentPackage" {
            # Retrieve all Software Update Deployment packages and export the Prestaged Content File (.pkgx) for each Deployment Package
            Get-CMDeploymentPackage -DistributionPointName $SourceDistributionPoint | ForEach-Object {Publish-CMPrestageContent -DeploymentPackage $_ -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.Name + ".pkgx"))}

        }

        "DriverPackage" {
            # Retrieve all Driver Packages and export the Prestaged Content File (.pkgx) for each Driver Package
            Get-CMDriverPackage -Fast | ForEach-Object {Publish-CMPrestageContent -DriverPackag $_ -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.Name + ".pkgx"))}

        }

        "OperatingSystemImage" {
            # Retrieve all Operating System Images and export the Prestaged Content File (.pkgx) for each Operating System Image
            Get-CMOperatingSystemImage | ForEach-Object {Publish-CMPrestageContent -OperatingSystemImage $_ -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.Name + ".pkgx"))}

        }

        "OperatingSystemInstaller" {
            # Retrieve all Operating System Installers and export the Prestaged Content File (.pkgx) for each Operating System Installer
            Get-CMOperatingSystemInstaller | ForEach-Object {Publish-CMPrestageContent -OperatingSystemInstaller $_ -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.Name + ".pkgx"))}

        }

        "Package" {
            # Retrieve all Legacy Software Distribution Packages and export the Prestaged Content File (.pkgx) for each Package
            Get-CMPackage -Fast | ForEach-Object {Publish-CMPrestageContent -Package $_ -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($_.Name + ".pkgx"))}

        }

    }

}
