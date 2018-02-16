# Tests

1. check for applied code of given gpo with keyname?  
Get-CimInstance -Namespace root\rsop\computer -Query "select * from rsop_securitysettings" | where {$_.gpoid -like '*{31b2f340-016d-11d2-945f-00c04fb984f9}*'} | where {$null -ne $_.KeyName}

2. check applied GPO:  
Get-CimInstance -Namespace root\rsop\computer -Query "select * from rsop_securitysettings"

3. get all gpo in domain:  
get-gpo -all -Domain 'objectivity.co.uk'






# Security
Check for all things harmj-y does and pester it


# BPA  
check for most common misconfigurationts and pester it
