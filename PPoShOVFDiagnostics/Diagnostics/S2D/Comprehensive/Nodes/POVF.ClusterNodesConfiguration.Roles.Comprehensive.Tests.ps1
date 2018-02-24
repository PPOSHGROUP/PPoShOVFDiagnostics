param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Roles Configuration Status" -Tags @('Configuration','Roles') {
    if($POVFConfiguration.Roles){
        Context 'Verify Roles configuration' {
            $hostRoles = Invoke-Command $POVFPSSession -ScriptBlock {
                Get-WindowsFeature
            }
            foreach($presentRole in $POVFConfiguration.Roles.Present.Name) {
                $presentRole
                it "Verify role {$presentRole} is installed" {
                    $testRole = $hostRoles | Where-Object {$PSItem.Name -eq $presentRole}
                    $testRole.Installed |Should Be $true
                }
            }
            if($POVFConfiguration.Roles.Absent) { 
                foreach($absentRole in $POVFConfiguration.Roles.Absent.Name) {
                    it "Verify role {$($absentRole.Name)} is installed" {
                        $testRole = $hostRoles | Where-Object {$PSItem.Name -eq $absentRole.Name}
                        $testRole.Installed |Should Be $false
                    }
                }
            }   
        }
    }
}