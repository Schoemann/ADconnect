# USE OF AD TO EXTRACT MEMBERS PER GROUP AND CREATE AN UPLOAD FILE FOR NRW CONNECT

# This script utilizes the Active Directory to get the members per group and creates
# an upload file to keep the groups in nrw connect up to date
# will possibly be used inside a windows task schedule to run autonomously

# required: ActiveDirectory module
# Workflow
## get AD groups
## get members per group
## build upload csv per group


# gets all members in AD Group

$space_name = $args[0]
$ad_group = $args[1]
$out_file = $args[2]

$users = get-adgroupmember -identity $ad_group -recursive | select-object SamAccountName

# create empty files
New-Item $out_file -force

# now check for each member its email address using get-aduser - properties emailaddress
for ($i=0;$i -lt $users.length; $i++){
$email = ""
$email = get-aduser -Identity $users[$i].samaccountname -Properties emailaddress | select EmailAddress
$email = $email.emailaddress
    If ([string]::IsNullOrEmpty($email)){
        #'Empty or Null'
        #write to no match file
      write-host $users[$i].samaccountname
    } Else {
      #  'Has stuff'
        #write to nrw connect file
     $res = "$email,$space_name-$ad_group"
     #write-host $res 
     Add-Content -Path $out_file -Value $res -Encoding UTF8
    }
}

