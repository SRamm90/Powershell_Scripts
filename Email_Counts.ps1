Get-ADOrganizationalUnit -filter * -property Description |
foreach {
$u=Get-ADUser -filter {EmailAddress -like "*"} -searchbase $_.distinguishedname -ResultPageSize 2000 -resultSetSize 500 -searchscope Onelevel
$total=($u | measure-object).count
$Enabled=($u | where {$_.Enabled} | Measure-Object).count
$Disabled=$total-$Enabled
New-Object psobject -Property @{
Name=$_.Name;
Active_Email_Addresses=$Enabled;
}
} | export-CSV -path .\results.csv