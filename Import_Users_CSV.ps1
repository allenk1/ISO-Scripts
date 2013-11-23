Import-Module ActiveDirectory

$inputFile = Import-CSV  C:\Users\Administrator\Desktop\import.csv
$log = "C:\Users\Administrator\Desktop\LOG-Import.log"
$date = Get-Date

Function createUsers {

    "Created Following User ( on " + $date + ")      :" | Out-File $log -Append
    "————————————————-" | Out-File $log -Append


    foreach($line in $inputFile)  {
        $sam = $line.sAMAccountName

        $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)"
        if (!$exists) {
            $sam = $line.sAMAccountName
            $pat = "OU=Customers, OU=Verasonics, DC=int, DC=Verasonics,DC=com"
            $pw = $line.Password

            new-aduser -SamAccountName $sam -Name $sam -AccountPassword (ConvertTo-SecureString -AsPlainText $pw -Force) -Enabled $true -DisplayName $sam
        } Else {
                "SKIPPED – ALREADY EXISTS OR ERROR : " + $sam | Out-File $log -Append
        }
    }

    "————————————————-" + "`n" | Out-File $log -Append

}

CreateUsers
