<#PSScriptInfo

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

The script can be used in two different ways:

1. The first method to use the script is to provide it with the desired Content Type and the Package Id's of the Items that belong to that Content Type.

The script supports the following Content Types:
 - Application
 - BootImage
 - DeploymentPackage
 - DriverPackage
 - OperatingSystemImage
 - OperatingSystemInstaller
 - Package

The user must also specify the Package ID's of Applications, Boot Images, (Software Update) Deployment Packages, etc. that belong to that specific Content Type.

2. The second method is to specify the full path to a CSV file that contains records for the ContentType and PackageId:
ContentType, PackageId
Application, PTS0000A
Application, PTS0000C
BootImage, PTS00003
Package, PTS00001

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
The full path to a comma-separated value file with 2 column headers: ContentType and PackageId

Example:
ContentType, PackageId
Application, PTS0000A
Application, PTS0000C
BootImage, PTS00003
Package, PTS00001

.EXAMPLE
Generate Prestaged Content Files (.pkgx) from the Applications that have the specified Package IDs and that are located on the Distribution Point "MCM-01.poltis.ca" and save them to the Output Folder "E:\PrestagedContent"

Export-CMPrestagedContent -SiteCode PTS -SourceDistributionPoint MCM-01.poltis.ca -OutputFolderPath E:\PrestagedContent -ContentType Application -PackageIds PTS00009, PTS0000C, PTS0000D

.EXAMPLE
Generate Prestaged Content Files (.pkgx) based on the information (Content Type and Package Id) stored in the CSV input file "ContentItems.csv" and save them to the Output Folder "E:\PrestagedContent"

Export-CMPrestagedContent -SiteCode PTS -SourceDistributionPoint MCM-01.poltis.ca -OutputFolderPath E:\PrestagedContent -InputFilePath .\ContentItems.csv

#>

[CmdletBinding(DefaultParameterSetName = 'PackageIds')]
param (
    [Parameter(Position = 0, ParameterSetName='PackageIds', Mandatory=$true)]
    [Parameter(Position = 0, ParameterSetName='InputFile', Mandatory=$true)]
    [String]
    $SiteCode,

    [Parameter(Position = 1, ParameterSetName='PackageIds', Mandatory=$true)]
    [Parameter(Position = 1, ParameterSetName='InputFile', Mandatory=$true)]
    [String]
    $SourceDistributionPoint,

    [Parameter(Position = 2, ParameterSetName='PackageIds', Mandatory=$true)]
    [Parameter(Position = 2, ParameterSetName='InputFile', Mandatory=$true)]
    [String]
    $OutputFolderPath,

    [Parameter(Position = 3, ParameterSetName='PackageIds', Mandatory=$true)]
    [ValidateSet("Application", "BootImage", "DeploymentPackage", "DriverPackage", "OperatingSystemImage", "OperatingSystemInstaller", "Package")]
    [String]
    $ContentType,

    [Parameter(Position = 4, ParameterSetName='PackageIds', Mandatory=$true)]
    [String[]]
    $PackageIds,

    [Parameter(Position = 3, ParameterSetName='InputFile', Mandatory=$true)]
    [String]
    $InputFilePath

)

function Export-CMPrestagedFiles {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory=$true)]
        [String]
        $SourceDistributionPoint,
    
        [Parameter(Position = 1, Mandatory=$true)]
        [String]
        $OutputFolderPath,

        [Parameter(Position = 2, Mandatory=$true)]
        [ValidateSet("Application", "BootImage", "DeploymentPackage", "DriverPackage", "OperatingSystemImage", "OperatingSystemInstaller", "Package")]
        [String]
        $ContentType,

        [Parameter(Position = 3, Mandatory=$true)]
        [String[]]
        $PackageIds
    )

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

                    Write-Error "Failed to find the Application with Package Id $PackageId."

                }
                else {
                
                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -Application $Application -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
                
                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the Application with Package ID $PackageId."
                        
                    }
                    <#
                    else {

                        Write-Error "Failed to export the Prestaged Content Files for the Application with Package Id $PackageId. `nThe Error Message was: $($Error[0].Exception.Message)`n"
                    
                    }
                    #>

                }
            
            }

        }

        "BootImage" {

            $AllBootImages = Get-CMBootImage

            # Retrieve all Boot Images with matching Package IDs and export the Prestaged Content File (.pkgx) for each Boot Image
            foreach ($PackageId in $PackageIds) {

                $BootImage = $AllBootImages | Where-Object {$_.PackageId -eq $PackageId}

                if (-not $BootImage) {

                    Write-Error "Failed to find the Boot Image with Package Id $PackageId."

                }
                else {

                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -BootImage $BootImage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
                
                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the Boot Image with Package Id $PackageId."
                        
                    }

                }
            }

        }

        "DeploymentPackage" {

            $AllDeploymentPackages = Get-CMSoftwareUpdateDeploymentPackage

            # Retrieve all (Software Update) Deployment packages with matching Package IDs and export the Prestaged Content File (.pkgx) for each Deployment Package
            foreach ($PackageId in $PackageIds) {

                $DeploymentPackage = $AllDeploymentPackages | Where-Object {$_.PackageId -eq $PackageId}

                if (-not $DeploymentPackage) {

                    Write-Error "Failed to find the (Software Update) Deployment Package with Package Id $PackageId."

                }
                else {

                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -DeploymentPackage $DeploymentPackage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
                    
                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the (Software Update) Deployment Package with Package Id $PackageId."
                    
                    }

                }
            }
            
        }

        "DriverPackage" {

            $AllDriverPackages = Get-CMDriverPackage

            # Retrieve all Driver Packages with matching Package IDs and export the Prestaged Content File (.pkgx) for each Driver Package
            foreach ($PackageId in $PackageIds) {

                $DriverPackage = $AllDriverPackages | Where-Object {$_.PackageId -eq $PackageId}

                if (-not $DriverPackage) {

                    Write-Error "Failed to find the Driver Package with Package Id $PackageId."

                }
                else {
                    
                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -DriverPackage $DriverPackage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))

                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the Driver Package with Package Id $PackageId."
                    
                    }

                }

            }

        }

        "OperatingSystemImage" {
            
            $AllOperatingSystemImages = Get-CMOperatingSystemImage

            # Retrieve all Operating System Images with matching Package IDs and export the Prestaged Content File (.pkgx) for each Operating System Image
            foreach ($PackageId in $PackageIds) {

                $OperatingSystemImage = $AllOperatingSystemImages | Where-Object {$_.PackageId -eq $PackageId}

                if (-not $OperatingSystemImage) {

                    Write-Error "Failed to find the Operating System Image with Package Id $PackageId."

                }
                else {

                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -OperatingSystemImage $OperatingSystemImage -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
                
                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the Operating System Image with Package Id $PackageId."
                    
                    }   
            
                }
        
            }
        
        }

        "OperatingSystemInstaller" {

            $AllOperatingSystemInstallers = Get-CMOperatingSystemInstaller

            # Retrieve all Operating System Installers with matching Package IDs and export the Prestaged Content File (.pkgx) for each Operating System Installer
            foreach ($PackageId in $PackageIds) {

                $OperatingSystemInstaller = $AllOperatingSystemInstallers | Where-Object {$_.PackageId -eq $PackageId}

                if (-not $OperatingSystemInstaller) {

                    Write-Error "Failed to find the Operating System Installer with Package Id $PackageId."

                }
                else {
                
                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -OperatingSystemInstaller $OperatingSystemInstaller -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))

                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the Operating System Installer with Package Id $PackageId."
                    
                    }

                }
            
            }

        }

        "Package" {
        
            $AllPackages = Get-CMPackage

            # Retrieve all (Legacy Software Distribution) Packages with matching Package IDs and export the Prestaged Content File (.pkgx) for each Package
            foreach ($PackageId in $PackageIds) {

                $Package = $AllPackages | Where-Object {$_.PackageId -eq $PackageId}

                if (-not $Package) {

                    Write-Error "Failed to find the (Legacy Software Distribution) Package with Package Id $PackageId."

                }
                else {
                
                    $error.PSBase.Clear()

                    Publish-CMPrestageContent -Package $Package -DistributionPointName $SourceDistributionPoint -FileName (Join-Path $ContentTypeDirectory ($PackageId + ".pkgx"))
                
                    if (-not $error) {

                        Write-Host "`nSuccessfully exported the Prestaged Content Files for the (Legacy Software Distribution) Package with Package Id $PackageId."
                    
                    }

                }
            
            }
            
        }

    }

}

#
#
# Main Body of the Script
#
#

$ErrorActionPreference = 'Continue'

$CMPSSuppressFastNotUsedCheck = $true

# Import the Configuration Manager PowerShell Module
Import-Module -Name "$ENV:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1" -ErrorAction Stop

# Set the current location to the SMS Site Code PowerShell Drive
Set-Location "$($SiteCode):"

# If the user specified the ContentType and PackageIds parameters
if ($ContentType -and $PackageIds) {

    # Call the Export-CMPrestagedFiles function and pass it the values for the ContentType and PackageIds parameters
    Export-CMPrestagedFiles -SourceDistributionPoint $SourceDistributionPoint -OutputFolderPath $OutputFolderPath -ContentType $ContentType -PackageIds $PackageIds

}
# If the user specified the InputFilePath parameter
elseif ($InputFilePath) {

    # Verify that the Input File exists
    if (-not (Test-Path -Path $InputFilePath)) {
        
        throw "`nFailed to find the CSV Input File: $InputFilePath." 
    }
    else {

        # Import the CSV Input File. Import-CSV creates an array of PSCustomObject objects
        $ContentTypePackgeIds = Import-CSV -Path $InputFilePath

        # Verify the schema of the CSV Input File by retrieveing the Note Properties of the PSCustomObject objects
        $ColumnHeaders = $ContentTypePackgeIds | Get-Member -MemberType NoteProperty | Sort-Object -Property Name

        # Verify that the PSCustomObject objects have two Note (Static) Properties named "ContentType" and "PackageId"
        if (($ColumnHeaders[0].Name -ne "ContentType") -or ($ColumnHeaders[1].Name -ne "PackageId")) {

            throw "`nThe script requires a CSV file that has 2 column headers: ContentType and PackageId."

        }

        # Group the objects by Content Type and call the Export-CMPrestagedFiles function for each ContentType
        $ContentTypeGroups = $ContentTypePackgeIds | Group-Object -Property ContentType

        foreach ($ContentTypeGroup in $ContentTypeGroups) {

            # The ContentType is the value of the Name property - the property used for creating the groups
            $ContentType = $ContentTypeGroup.Name
            
            # Copy the PackageId property of each Group that has the same Name (ContentType)
            $PackageIds = $ContentTypeGroup.Group | ForEach-Object {$_.PackageId}

            # Call the Export-CMPrestagedFiles function and pass it the ContentType and PackageIds parameters
            Export-CMPrestagedFiles -SourceDistributionPoint $SourceDistributionPoint -OutputFolderPath $OutputFolderPath -ContentType $ContentType -PackageIds $PackageIds

        }

    }
}
