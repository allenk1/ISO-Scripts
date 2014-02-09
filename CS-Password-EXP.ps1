#=====================================================================================================#
# Author: Jim Sullivan
# # Updated: 04/24/2013
# Verson: 1
#
# Purpose:
# Powershell script to find out a list of users
# whose password is expiring within x number of days (as specified in $days_before_expiry).
# Email notification will be sent to them reminding them that they need to change their password.
#
# Requirements:
# Quest ActiveRoles cmdlets (http://www.quest.com/powershell/activeroles-server.aspx)
# 
# Script must be run as a user with Permission to view AD Attributes, Domain Admin for example.
#
#=====================================================================================================#
#Add Snapins
Add-PSSnapin "Quest.ActiveRoles.ADManagement" -ErrorAction SilentlyContinue

#Get todays date for use in the script
$date = Get-Date

#===========================#
#User Adjustable Variables #
#===========================#

# How many Days Advanced Warning do you want to give?
$DaysOfNotice = 14

#Generate a Admin report?
$ReportToAdmin = $true
#$ReportToAdmin = $false

#Sort Report
#===========================#
# 0 = By OU
# 1 = First Name Ascending
# 2 = Last Name Ascending
# 3 = Expiration Date Ascending
# 4 = First Name Descending
# 5 = Last Name Descending
# 6 = Expiration Date Descending
#===========================#
$ReportSortBy=0

#Alert User?
$AlertUser = $true
#$AlertUser = $false

#URL for self Service
#$URLToSelfService = "http://"

#Mail Server Variables
$FromAddress = "DoNotReply@recology.com"
$RelayMailServer = "10.1.2.50"
$AdminEmailAddress ="jsullivan@recology.com"

# Define font and font size
# ` or \ is an escape character in powershell
$font = "<font size=`"3`" face=`"Calibri`">"

# List of users whose Password is about to expire. The following line can be added to limit OU's searched if so desired
#$users += Get-QADUser -SearchRoot 'DN' -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}
#$users = Get-QADUser -SearchRoot 'OU= Company USERS,DC=contoso,DC=com' -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}
#$users += Get-QADUser -SearchRoot 'OU=INTERNATIONAL OFFICE USERS,DC=contoso,DC=com' -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}

# Search Whole Root
#$users = Get-QADUser -SearchRoot 'OU=Recology Exp Test,DC=norcalwaste,DC=com' -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}
$users = Get-QADUser -SearchRoot 'OU=Cleanscapes,OU=Branch locations,DC=norcalwaste,DC=com' -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}
#$users = Get-QADUser -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}

#===========================#
#Main Script				#
#===========================#

# Sort Report
Switch ($ReportSortBy)
{
'0' {$users}
'1' {$users = $users | sort {$_.FirstName}}
'2' {$users = $users | sort {$_.LastName}}
'3' {$users = $users | sort {$_.PasswordExpires}}
'4' {$users = $users | sort -Descending {$_.FirstName}}
'5' {$users = $users | sort -Descending {$_.LastName}}
'6' {$users = $users | sort -Descending {$_.PasswordExpires}}
}

if ($ReportToAdmin -eq $true)
{
#Headings used in the Admin Alert
$Title="<h1><u>Password Expiration Status and Alert Report</h1></u><h4>Generated on " + $date + "</h4>"
$Title+="<font color = red><h2><u>Admin Action Required</h2></u></font>"
$Title+="<font size=`"3`" color = red> An Admin needs to update these accounts so that users can be notified of pending or past password expiration<br></font>"
$Title_ExpiredNoEmail="<h3><u>Users Have Expired Passwords And No Primary SMTP to Notify Them</h3></u>"
$Title_AboutToExpireNoEmail="<h3><u>Users Password's Is About To Expire That Have No Primary SMTP Address</h3></u>"
$Title2="<br><br><h2><u><font color= red>No Admin Action Required - Email Sent to User</h2></u></font>"
$Title_Expired="<h3><u>Users With Expired Passwords</h3></u>"
$Title_AboutToExpire="<h3><u>Users Password's About To Expire</h3></u>"
$Title_NoExpireDate="<h3><u>Users with no Expiration Date</u></h3>"
}
#For loop to report
foreach ($user in $users)
{

if ($user.PasswordExpires -eq $null)
{
$UsersList_WithNoExpiration += $user.Name + " (<font color=blue>" + $user.LogonName + "</font>) does not seem to have a Expiration Date on their account.<font color=Green> <br>OU Container: " + $user.DN + "</font> <br>"
}
Elseif ($user.PasswordExpires -ne $null)
{
#Calculate remaining days till Password Expires
$DaysLeft = (($user.PasswordExpires - $date).Days)

#Days till password expires
$DaysLeftTillExpire = [Math]::Abs($DaysLeft)

#If password has expired
If ($DaysLeft -le 0)
{
#If the users don't have a primary SMTP address we'll report the problem in the Admin report
if (($user.Email -eq $null) -and ($user.UserMustChangePassword -ne $true) -and ($ReportToAdmin -eq $true))
{
#Add it to admin list to report on it
$UserList_ExpiredNoEmail += $user.name + " (<font color=blue>" + $user.LogonName + "</font>) password has expired " + $DaysLeftTillExpire + " day(s) ago</font>. <font color=Green> <br>OU Container: " + $user.DN + "</font> <br><br>"
}

#Else they have an email address and we'll add this to the admin report and email the user.
elseif (($user.Email -ne $null) -and ($user.UserMustChangePassword -ne $true) -and ($AlertUser -eq $True))
{
$ToAddress = $user.Email
$Subject = "Notice: Your Windows Password expired."
$body = " "
$body = $font
$body += "Hello (<font color=blue> " + $user.Name + "</font>), <br><br>"
$body += "This is an auto-generated email to remind you that your Windows Password for account - <font color=red>" + $user.LogonName + "</font> - has expired. <br><br>"
$body += "Recology's company policy requires you to update your password every 90 days. Please comply with this policy by updating your password now.. "
$body += "Before changing your password please make sure that you don't have an active Tower session open. If you have Tower Open, Right Click on your name and click on Close. "
$body += "In order to change your password, go to the Start button, select Windows Security, and click the Change Password button. "
$body += "For detailed instructions on changing your passwords, please review the Quick Reference Guide on changing passwords located at: "
$body += "S:\Documentation\Quick Reference Guides\Changing Passwords.docx "
$body += "If you get a login error when launching Tower after changing your password, please log off of your Desktop session and log back on with your new password, then open Tower again. "
$body += "Failure to update your password in a timely manner will result in an account lockout and you will not be able to access any Recology applications until your Liaison<br>
contacts User Support and requests a password reset."
$body += " <br><br><br><br>"
$body += "<h4>Thank you for your prompt attention to this issue, and please do not share your password with anyone.</h4>"
$body += "<h5>Message generated on: " + $date + ". <font color=red>Do not reply to this message, any replies will be rejected by the system. If you need assistance, please contact your office liaison.</font></h5>"
$body += "</font>"

Send-MailMessage -smtpServer $RelayMailServer -from $FromAddress -to $user.Email -subject $Subject -BodyAsHtml -body $body

}
if ($ReportToAdmin -eq $true)
{
#Add it to a list
$UserList_ExpiredHasEmail += $user.name + " (<font color=blue>" + $user.LogonName + "</font>) password has expired " + $DaysLeftTillExpire + " day(s) ago</font>. <font color=Green> <br>OU Container: " + $user.DN + "</font> <br><br>"
}
}
elseif ($DaysLeft -ge 0)
{
#If Password is about to expire but the user doesn't have a primary address report that in the Admin report
if (($user.Email -eq $null) -and ($user.UserMustChangePassword -ne $true) -and ($ReportToAdmin -eq $true))
{
#Add it to admin list
$UserList_AboutToExpireNoEmail += $user.name + " (<font color=blue>" + $user.LogonName + "</font>) password is about to expire and has " + $DaysLeftTillExpire + " day(s) left</font>. <font color=Green> <br>OU Container: " + $user.DN + "</font> <br><br>"
}
# If there is an email address assigned to the AD Account send them a email and also report it in the admin report
elseif (($user.Email -ne $null) -and ($user.UserMustChangePassword -ne $true) -and ($AlertUser -eq $True) )
{
#Setup email to be sent to user
$ToAddress = $user.Email
$Subject = "Notice: Your Windows Password is about to expire."
$body = " "
$body = $font
$body += "Hello <font color=blue> " + $user.Name + "</font>, <br><br>"
$body += "This is an auto-generated email to remind you that your Windows Password for account - <font color=red>" + $user.LogonName + "</font> - is about to expire. <br><br>"
$body += "Recology's company policy requires you to update your password every 90 days. Please comply with this policy by updating your password now.. <br><br>"
$body += "In order to change your password, go to the Start button, and select Settings and then select Windows Security, and click the Change Password button. <br><br>"
$body += "For detailed instructions on changing your passwords, please review the Quick Reference Guide on changing passwords located at:<br><br> "
$body += "<a href=\\norcalsrv01\norcal\Documentation\Quick%20Reference%20Guides\Changing%20Passwords.docx>S:\Documentation\Quick Reference Guides\Changing Passwords.docx</a><br><br>"
$body += "Failure to update your password in a timely manner will result in an account lockout and you will not be able to access any Recology applications until your Liaison<br>
contacts User Support and requests a password reset."
$body += " <br><br>"
$body += "<h4>Thank you for your prompt attention to this issue, and please do not share your password with anyone.</h4>"
$body += "<h5>Message generated on: " + $date + ". <font color=red>Do not reply to this message, any replies will be rejected by the system. If you need assistance, please contact your office liaison.</font></h5>"
$body += "</font>"

Send-MailMessage -smtpServer $RelayMailServer -from $FromAddress -to $user.Email -subject $Subject -BodyAsHtml -body $body

}
if ($ReportToAdmin -eq $true)
{
#Add it to admin Report list
$UserList_AboutToExpire += $user.name + " <font color=blue>(" + $user.LogonName + "</font>) password is about to expire and has " + $DaysLeftTillExpire + " day(s) left</font>. <font color=Green> <br>OU Container: " + $user.DN + "</font> <br><br>"
}
}
}
} # End foreach ($user in $users)

if ($ReportToAdmin -eq $true)
{
If ($UserList_AboutToExpire -eq $null) {$UserList_AboutToExpire = "No Users to Report"}
If ($UserList_AboutToExpireNoEmail -eq $null){ $UserList_AboutToExpireNoEmail = "No Users to Report"}
if ($UserList_ExpiredHasEmail -eq $null) {$UserList_ExpiredHasEmail = "No Users to Report"}
if ($UserList_ExpiredNoEmail -eq $null) {$UserList_ExpiredNoEmail = "No Users to Report"}
if ($UsersList_WithNoExpiration -eq $null) {$UsersList_WithNoExpiration = "No Users to Report"}

#Email Report to Admin
$Subject="Password Expiration Status for " + $date + "."
$AdminReport = $font + $Title + $Title_ExpiredNoEmail + $UserList_ExpiredNoEmail + $Title_AboutToExpireNoEmail + $UserList_AboutToExpireNoEmail + $Title_AboutToExpire + $UserList_AboutToExpire + $Title_Expired + $UserList_ExpiredHasEmail + $Title_NoExpireDate + $UsersList_WithNoExpiration + "</font>"
Send-MailMessage -smtpServer $RelayMailServer -from $FromAddress -to $AdminEmailAddress -subject $Subject -BodyAsHtml -body $AdminReport
}