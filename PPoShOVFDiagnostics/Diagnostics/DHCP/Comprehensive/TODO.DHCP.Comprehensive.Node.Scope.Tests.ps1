param(
  $POVFPSSession,
  $POVFConfigurationScope

)

Describe "DHCP Scope Settings on Server {$($POVFConfigurationScope.ComputerName)}" -Tags Scope,Configuration {
    Context "General Scope Settings" {
        It "Scope Id should match configuration" {

        }
        It "Scope Start Range should match configuration" {

        }
        It "Scope End Range should match configuration" {

        }
        It "Scope Subnet Mask should match configuration" {

        }
        It "Lease Duration shoul match configuration" {

        }
        It "Exclusion Range should match configuration" {

        }
    }
    Context "Scope Options should match configuration" {
        foreach ($option in $POVFConfigurationScope.ScopeOptions) {
            It "Scope option {} should match configuration {}" {

            }
            It "Scope Value for Option {} should match configuration" {

            }
        }
    }
}