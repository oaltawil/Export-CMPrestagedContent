# Export-CMPrestagedContent
A sample script to generate prestaged content files (.pkgx) from a Configuration Manager distribution point. The script must be executed on a computer that has the Microsoft Configuration Manager Administrative Console installed.

Examples:

1. Generate Prestaged Content Files (.pkgx) from all supported CM Content Types (Applications, Boot Images, Software Update Deployment Packages, etc.) that are located on the Distribution Point "MCM-01.poltis.ca" and save them to the Output Folder "E:\PrestagedContent":

      Export-CMPrestagedContent -SiteCode "PTS" -SourceDistributionPoint "MCM-01.poltis.ca" -OutputFolderPath "E:\PrestagedContent"

2. Generate Prestaged Content Files (.pkgx) from all Applications that are located on the Distribution Point "MCM-01.poltis.ca" and save them to the Output Folder "E:\PrestagedContent"

      Export-CMPrestagedContent -SiteCode "PTS" -SourceDistributionPoint "MCM-01.poltis.ca" -OutputFolderPath "E:\PrestagedContent" -ContentType "Application"
