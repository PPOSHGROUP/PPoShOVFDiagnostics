param(
    $POVFConfiguration,
    $POVFPSSession
)
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Registry Configuration Status" -Tags @('Configuration','Registry') {
    if($POVFConfiguration.RegistryEntry){ 
        Context "Verify Registry Entries" {
            foreach ($rEntry in $POVFConfiguration.RegistryEntry) {
                it "Verify Registry Entry {$($rEntry.Name)} in {$($rEntry.Path)}" {
                    $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                        Get-ItemProperty -Path $USING:rEntry.Path -Name $USING:rEntry.Name -ErrorAction SilentlyContinue
                    }
                    $rValue = [convert]::ToInt64($rEntry.Value,16)
                    $test.($rEntry.Name) | Should Be $rValue
                }

            }

        }
    }
}