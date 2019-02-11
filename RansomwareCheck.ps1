
################################################
# Configure the variables below
################################################
# Step 1. Specify the HoneyPot and Witness File & Folder locations along with the testing interval in seconds
$HoneypotDir =@("C:\AllData\Share1","C:\AllData\Share2","C:\AllData\Share3")
$HoneypotFile = "HoneypotFile.docx" 
$HoneypotWitenessDir = "C:\zzzWitness"
$TestInterval = "3"
# Step 2. Specify the SMTP Email Settings
$EmailTo = "TechSupport@esp-cc.net"
$EmailFrom = "RansomDetected@esp-cc.net"
$SMTPServer = "mail.ebglobal.com"
$SMTPPort = "587"
$SMTPUser =
$SMTPPassword =
$SMTPSSLEnabled = "FALSE"
########################################################################################################################
# DO NOT EDIT BELOW THIS LINE
########################################################################################################################
$HoneypotWitnessFile = $HoneypotFile
$emailsetting = New-Object System.Net.Mail.MailMessage
$Emailsetting.to.add($EmailTo)
$Emailsetting.from = $EmailFrom
$Emailsetting.IsBodyHTML = "TRUE"
$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
if ($SMTPSSLEnabled -eq "TRUE")
{
$smtp.EnableSSL = "TRUE"
}
$smtp.Credentials = New-Object System.Net.NetworkCredential($SMTPUser, $SMTPPassword);
################################################################################################
# Starting Continuous Loop of Ransomware Check
################################################################################################
Do {
for($i=0; $i -lt $HoneypotDir.length; $i++){
# Testing to see if file exists first, the extension may of changed or it may have been deleted
$TestHoneypotPath = test-path ($HoneypotDir[$i]+"\$HoneypotFile")
if ($TestHoneypotPath -eq $False)
{
# File not found or renamed from original file
$HoneyPotFileFound = Get-ChildItem $HoneypotDir[$i] | Sort {$_.LastWriteTime} | select Name -expandproperty Name -last 1
$HoneyPotFileLastWriteTime = Get-ChildItem ($HoneypotDir[$i]+"\$HoneyPotFileFound") | select lastwritetime
$HoneyPotFileOwner = get-acl ($HoneypotDir[$i]+"\$HoneyPotFileFound") | select owner
# Configuring email settings
$EmailSubject = "Potential Ransomware Infection Found"
$EmailBody = "Honeypot file "+$HoneypotDir[$i]+"\$HoneypotFile on $env:computername has been deleted or file extension changed.
Found $HoneyPotFileFound instead, modified by $HoneyPotFileOwner @ $HoneyPotFileLastWriteTime indicating a possbile ransomware infection."
# Outputting to screen
write-host $EmailBody
# Stopping loop of script
$StopScript ="Y"
# Disabling File share service
#--------------------Stop-Service "LanmanServer" -force –PassThru
# Building email Subject & Body
$Emailsetting.subject = $EmailSubject
$Emailsetting.body = $EmailBody
# Sending Email
Try
{
$smtp.send($Emailsetting) 
}
Catch [system.exception]
 {
 # Trying to send email again if first attempt fails
sleep 10
$smtp.send($Emailsetting)
 }
Finally
 {
 }
# Finished sending email
stop-computer -Force
}
################################################
# If the Honeypot file does exist running a comparison of the Honeypot and test files
################################################
if ($TestHoneypotPath -eq $True)
{
# File found so comparing files
try
{
# If file is currently being encrypted the get-content can fail, so adding try command with a wait
$ReadHoneypotFile = Get-Content ($HoneypotDir[$i]+"\$HoneypotFile")
}
catch
{
sleep 60
$ReadHoneypotFile = Get-Content ($HoneypotDir[$i]+"\$HoneypotFile")
}
# Reading test file
$ReadHoneypotWitenessFile = Get-Content "$HoneypotWitenessDir\$HoneypotWitnessFile"
# Comparing files to check for modifications
if (Compare-Object $ReadHoneypotFile $ReadHoneypotWitenessFile)
{
$HoneypotFileMatch = "FALSE"
}
else
{
$HoneypotFileMatch = "TRUE"
}
################################################
# If the Honeypot and test files do not match
################################################
if ($HoneypotFileMatch -eq "FALSE")
{
$HoneyPotFileLastWriteTime = Get-ChildItem ($HoneypotDir[$i]+"\$HoneypotFile") | select lastwritetime
$HoneyPotFileOwner = get-acl ($HoneypotDir[$i]+"\$HoneypotFile") | select owner
# Configuring email settings
$EmailSubject = "Potential Ransomware Infection Found"
$EmailBody = "Honeypot file "+$HoneypotDir[$i]+"\$HoneypotFile on $env:computername has been modified by $HoneyPotFileOwner @ $HoneyPotFileLastWriteTime.
Indicative of a potential ransomware infection."
# Outputting to screen
write-host $EmailBody
# Stopping loop of script
$StopScript ="Y"
# Sending email
Try
{
$smtp.send($Emailsetting) 
}
Catch [system.exception]
 {
 # Trying to send email again if first attempt fails
sleep 10
$smtp.send($Emailsetting)
 }
Finally
 {
 }
# Finished sending email
stop-computer -Force
}
################################################
# If the Honeypot and witness files MATCH then no ransomware infection detected and script loops to the start where it sleeps for the $TestInterval
################################################
# if the files were found and do match
if ($HoneypotFileMatch -eq "TRUE")
{
# Files do match, repeating test in 
$Message = "No infection detected, repeating in $testinterval seconds"
write-host $Message
$StopScript = "N"
}
# End of Honeypot File does exist below
}
# End of Honeypot File does exist above
sleep $TestInterval
#
}
}# End of Do Loop
Until ($StopScript -eq "Y")
