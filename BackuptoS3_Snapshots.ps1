# +---------------------------------------------------------------------------
# | File : BackuptoS3_Snapshots.ps1
# | Version : 1.0
# | Purpose : Backs up shadow copies to S3 & EBS snapshots
# | Synopsis:
# | Usage : .\BackuptoS3_Snapshots.ps1
# +----------------------------------------------------------------------------
# |
# | File Requirements:
# | Must have AWS S3 CLI installed & Powershell tools
# | CLI - https://s3.amazonaws.com/aws-cli/AWSCLI64.msi
# | PS Tools - http://aws.amazon.com/powershell/
# +----------------------------------------------------------------------------
# | Maintenance History
# | View GitHub notes:
# ********************************************************************************


# Default input params
$access = "AKIAJGXXXXXXXXXXXXXX"
$private = "ABC123123ABC123123ABC123123ABC123123ABCD"
$vol_id = @("vol-XXXXXXXX", "vol-XXXXXXXX")
$servername = "Server_NAME"
$region = "us-west-2"   # Regions: us-east-1, us-west-2, us-west-1, eu-west-1, ap-southeast-1
                        # ap-southeast-2, ap-northeast-1, sa-east-1

# $a = Get-Date
# $date = $a.Year + "_" + $a.Month + "_" + $a.Day   #YYYYMMDD
$date = Get-Date -format s

import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

# Clear any saved credentials
# Clear-AWSCredentials -StoredCredentials

# Set credentials
Set-AWSCredentials -AccessKey $access -SecretKey $private
Set-DefaultAWSRegion $region

# Loop through all volumes and create snapshots
# Naming Scheme ServerName_VOLID

foreach ($vol in $vol_id) {

    # snapshot the EBS store
    $snapshot_name = $servername + "_" + $vol + "_" + $date

    New-EC2Snapshot -VolumeId $vol -Description $snapshot_name

}

# Now flat file copy to S3
# Enable Bucket versioning in order to keep mulitple version of the file
# TODO: Version with Script

$copy_dirs = @('C:\Path\to\Backup\Directory')
$bucket = "bucketname"

foreach ($dir in $copy_dirs){

    # Key setup by ServerName_DATE
    $key = $servername + '_' + $date
    Write-S3Object -Folder $dir -BucketName $bucket -KeyPrefix / -Recurse

}



