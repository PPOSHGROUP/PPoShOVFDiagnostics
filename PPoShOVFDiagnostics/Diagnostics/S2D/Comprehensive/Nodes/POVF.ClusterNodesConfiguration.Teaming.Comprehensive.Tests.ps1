param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Teaming Configuration Status" -Tags @('Configuration','Teaming') {
    if($POVFConfiguration.Team){ 
        Context "Verify Network Team Configuration" {
            foreach ($team in $POVFConfiguration.Team) {
                $hostTeam = Invoke-Command $POVFPSSession -ScriptBlock {
                    Get-NetLbfoTeam -Name $USING:team.TeamName
                }
                it "Verify Team {$($team.TeamName)} exists" {
                    $hostTeam | Should -Not -BeNullOrEmpty
                }
                it "Verify Team {$($team.TeamName)} TeamingMode" {
                    $hostTeam.TeamingMode | Should Be $team.TeamingMode 
                }
                it "Verify Team {$($team.TeamName)} LoadBalancingAlgorithm" {
                    $hostTeam.LoadBalancingAlgorithm | Should Be $team.LoadBalancingAlgorithm
                }
                it "Verify Team {$($team.TeamName)} TeamMembers" {
                    Compare-Object -ReferenceObject $team.TeamMembers -DifferenceObject $hostTeam.Members  | Should -BeNullOrEmpty 
                }
            }
        }
    }
}