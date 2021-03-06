# Get script Start Time (used to measure run time)
$startDTM = (Get-Date)

#Define location of script variable
#the -parent switch returns one directory lower from directory defined. 
#below will return up to ImportADUsers folder 
#and since files are located here it will find it.
#It fails withpout appending "*.*" at the end
#This file is required to update fields for existing users
#Modify this script to create new users in UnifiedGov domain


$path = Split-Path -parent "C:\"

#Create log date and user disabled date

$logdate = Get-Date -Format ddmmyyyy

$userdisableddate = Get-Date

#Define CSV and log file location variables
#they have to be on the same location as the script

$csvfile = $path + "GAL-FINAL.csv"
$logfile = $path + "logs\$logdate.logfile.txt"
$scriptrunrime = $path + "logs\scripttime.txt"

#Define variable for a server with AD web services installed

$ADServer = 'XXXX'

#define searchbase variable

#$SearchBase = "OU=ELITE LC,DC=elitelc,DC=corp"

#Get Admin account credential

$GetAdminact = Get-Credential 

#Import Active Directory Module

Import-Module ActiveDirectory

#Import CSV file and update users in the OU with details from the file
#Create the function script to update the users

Function Update-ADUsers {

Import-Csv -path $csvfile | `

ForEach-Object { 

$GivenName = $_.FirstName
$Surname = $_.LastName
$DisplayName = $_.DisplayName
$StreetAddress = $_.Address
$Title = $_.'Title'
$City = $_.City
$State = $_.State
$PostCode = $_.PostalCode 
$Country = $_.CountryorRegion 
#----$Title = $_.'Job Title'
$Company = $_.Company
#----$Description = $_.Description
#----$Department = $_.Department
$Office = $_.DirectLine
#----$Phone = $_.Phone
$Mail = $_.Email
#----$Validation = $_.Validation
$Mobile = $_.Mobile
$Fax = $_.Fax

$Manager = $_.Manager
#This script below is useful because some domains may not have
#a uniform way of displaying DisplayNames. Some users may have
#display name as 'Lastname FirstName', others may have it as 
#'FirstNameLastname'. Below I have split the $Manager name into
#$ManagerFirstname and $ManagerLastname
$ManagerFirstname = $Manager.Split("")[0]
$ManagerLastname = $Manager.Split("")[-1]
#Then create different possible combinations to use in the $ManagerDN Search
$ManagerDN1 = "$ManagerFirstname" + "$ManagerLastname"
$ManagerDN2 = "$ManagerLastname" + " $ManagerFirstname"
$ManagerDN3 = "$ManagerLastname" + "$ManagerFirstname"
#Convert names to lower case. Appears to be case sensitive
$ManagerLC = $Manager.ToLower()
$ManagerDNLC1 = $ManagerDN1.ToLower()
$ManagerDNLC2 = $ManagerDN2.ToLower()
$ManagerDNLC3 = $ManagerDN3.ToLower()

$sam = $_.'SamAccountName'

#Included the If clause below to ignore execution if the $Manager variable
#from the csv is blank. Avoids throwing errors and saves execution time
#Used different possible displaynames to search for a managername
$ManagerDN = IF ($Manager -ne '') 
{(Get-ADUser -server $ADServer -Credential $GetAdminact -Filter `
{(Name -like $Manager) -or (Name -like $ManagerDN1) -or (Name -like $ManagerDN2) -or (Name -like $ManagerDN3) -or (Name -like $ManagerLC) -or (Name -like $ManagerDNLC1) -or (Name -like $ManagerDNLC2) -or (Name -like $ManagerDNLC3)}).DistinguishedName} #Manager required in DN format
#Changed managerdn filter above because Sutton users have displayname reversed

#change country to LDAP format, United Kingdom is 'GB'
If ($Country -eq "United States") {$Country = "US"} # {Out-File $logfile -append}

##First check whether $sam exisits in AD

Try { $SAMinAD = Get-ADUser -server $ADServer -Credential $GetAdminact -LDAPFilter "(sAMAccountName=$sam)"} 
Catch { }

#Execute set-aduser below only if $sam is in AD and also is in the excel file, else ignore#
    If($SAMinAD -ne $null -and $sam -ne '')
    {

#added the 'if clause' to ensure that blank fields in the CSV are ignored.
#the object names must be the LDAP names. get values using ADSI Edit
IF ($DisplayName -ne '') {{ Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{displayName=$DisplayName} }}
IF ($StreetAddress -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{StreetAddress=$StreetAddress} }
IF ($City -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{l=$City} }
IF ($State -ne '') { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{st=$state} } 
IF ($PostCode -ne '') { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{postalCode=$PostCode} }
#Country did not accept the -Replace switch. It works with the -Country switch
IF ($Country -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Country $Country } 
IF ($Title -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{Title="$Title"} }
IF ($Company -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{Company=$Company} }
#----IF ($Description -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{Description=$Description} }
#----IF ($Department -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{Department=$Department}  }
IF ($Office -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{telephoneNumber=$Office}  }
#----IF ($Phone -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{telephoneNumber=$Phone}  }
IF ($Mail -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{mail=$Mail} }
IF ($Mobile -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{mobile=$Mobile} }
IF ($Fax -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{facsimileTelephoneNumber=$Fax}  }
#Manager did not accept the -Replace switch. It works with the -manager switch
IF ($Manager -ne '' ) { Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Manager $ManagerDN} 
#Set a flag to indicate that the user has been updated on AD.
#When I export, I will omit all users with thie flag enabled 
#Added a condition to the export script to ignore any user with the word 'Google Migrated' on the info (Name) field
#The code below adds the word "Migrated" on the Notes fiels, Tepephone tab of the user. 
#The ldap name for the Notes field is 'info'
Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{info=' '} 
#Change name format to 'FirstName Lastname'
#This is essential because some Sutton users display as sAMAccountName
#Rename-ADObject renames the users in the $DisplayName format

$newsam = (Get-ADUser -identity $sam -server $ADServer -Credential $GetAdminact).DistinguishedName #Rename-ADObject accepts -Identity in DN format

Rename-ADObject -server $ADServer -Credential $GetAdminact -Identity $newsam -NewName $DisplayName

#For all users validated as 'Left', disable AD account

If ($Validation -eq 'Left')
#Disable the user
{ (Disable-ADAccount -server $ADServer -Credential $GetAdminact -Identity $sam)
#Include disable date stamp on all disabled users
(Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Replace @{ipPhone="$userdisableddate"} )
}

}
Else

{ #Log error for users that are not in Active Directory or with no Logon name in excel file
$DisplayName + " Not modified because it does not exist in AD or LogOn name field is empty on excel file" | Out-File $logfile -Append
}


}}
   
# Run the function script 
Update-ADUsers
#Finish
#The lins below calculates how long
#it takes to run this script
# Get End Time
$endDTM = (Get-Date)

# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"
"Elapsed Time: $(($endDTM-$startDTM).totalminutes) minutes"

#send the information to a text file

"$(($endDTM-$startDTM).totalseconds) seconds" > $scriptrunrime

#Append the minutes value to the text file

Add-Content -path $scriptrunrime "$(($endDTM-$startDTM).totalminutes) minutes"
#SCRIPT ENDS
