# USE OF AD TO EXTRACT MEMBERS PER GROUP AND CREATE AN UPLOAD FILE FOR NRW CONNECT

# This script utilizes the Active Directory to get all ad groups

# required: ActiveDirectory module
# Workflow
## get AD groups
# Get-ADGroup -Filter * | select Name,samaccountname
get-adgroup -filter * | select * | where groupscope -eq "Global" | select name