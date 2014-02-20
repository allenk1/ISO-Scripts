# +---------------------------------------------------------------------------
# | File : CopyfromAWStoLocal.ps1
# | Version : 1.0
# | Purpose : Copy files from S3 to Local Storage
# | Synopsis:
# | Usage : .\CopyfromAWStoLocal.ps1
# +----------------------------------------------------------------------------
# |
# | File Requirements:
# | Must have AWS S3 CLI installed & Powershell tools
# | CLI - https://s3.amazonaws.com/aws-cli/AWSCLI64.msi
# | PS Tools - http://aws.amazon.com/powershell/
# +----------------------------------------------------------------------------
# | Maintenance History
# | View GitHub notes: https://github.com/allenk1/ISO-Scripts/commits/master/BackuptoS3_Snapshots.ps1
# ********************************************************************************


# Default input params
$access = "ABC12312312312312312"
$private = "ABCDEFGHIJ1231231231ABCDEFGHIJ1231231231"
$foldernames = @("Dir1", "Dir2", "Dir3")
$bucket = "bucketname"
$downloadpath = "E:\"
$region = "us-west-2"   # Regions: us-east-1, us-west-2, us-west-1, eu-west-1, ap-southeast-1
                        # ap-southeast-2, ap-northeast-1, sa-east-1

import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

# Clear any saved credentials
# Clear-AWSCredentials -StoredCredentials

# Set credentials
Set-AWSCredentials -AccessKey $access -SecretKey $private
Set-DefaultAWSRegion $region

foreach ($dir in $foldernames){

    $store = $downloadpath + $dir
    Read-S3object -BucketName $bucket -KeyPrefix $dir -Folder $store

}



