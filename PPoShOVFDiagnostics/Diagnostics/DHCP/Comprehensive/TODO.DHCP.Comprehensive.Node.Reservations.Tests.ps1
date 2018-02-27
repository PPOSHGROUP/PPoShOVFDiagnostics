param (
    $POVFPSSession,
    $POVFConfiguration
)

Describe "DHCP Reservations Settings on Server {$($POVFConfigurationReservations.ComputerName)}" -Tags Reservations,Configuration {
    Context "Check Reservations Settings" {
       # $currentReservations = Get-DhcpServerv4Reservation
        It "Count should match configuration" {

        }

    }
}
Describe "Check each reservation - for given scope" -Tags Reservations,Configuration,List { 
    Context "Checking each reservation matching" {
        foreach ($reservation in $POVFCurrentReservations) {
            It "Scope option {} should match configuration {}" {

            }
            
        }
    }
}