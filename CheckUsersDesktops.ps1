# import Ad powershell
Import-Module activedirectory

# Results array
$resultsarray = "Computer, User, Count"

$date = Get-Date
$date = $date.ToString("yyyy-MM-dd")

$csvname = $date + "-desktop-items.csv"
$resultsarray | Add-Content -Path $csvname

# Search for all computers in AD
$computers = Get-ADComputer -Filter * -SearchBase "OU=test,DC=test,DC=test" | Select Name

# Get list of all users
$users = Get-ADUser -Filter 'enabled -eq $true' -SearchBase "OU=test,DC=test,DC=test"

$i = 0
foreach ($computer in $computers){
    foreach ($user in $users){
        $foldername = "\\" + $computer.Name + "\c$\Users\" + $user.SamAccountName + "\Desktop"
        $testpath = "\\" + $computer.Name + "\c$\Users\" + $user.SamAccountName
        if(Test-Path $testpath){

            $files = Get-ChildItem $foldername -Recurse -Force | Measure-Object 
            
           $results = "`n" + $computer.Name + ", " + $user.SamAccountName + ", " + $files.count
           Add-Content $csvname $results
        }
    }
    
    Write-Host "Scanned" $computer.Name
}

