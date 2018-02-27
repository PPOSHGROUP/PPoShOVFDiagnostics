param (
  [System.Management.Automation.PSCredential]$POVFCredential,
  $POVFConfiguration
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ComputerName -Credential $POVFCredential -SessionName 'POVF'
Describe "1" -Tag 'Operational' {
  Context '2' {
    it "3" {
      (Invoke-Command -Session $POVFPSSession -ScriptBlock {
          Get-Service WinRM
      }).Status  | Should Be 'Running'
    }
  }
  Context '4' {
    it '5' {
      $true | Should -Be $True
    }
  }
}
Get-PSSession -Name 'POVF*' | Remove-PSSession -ErrorAction SilentlyContinue  