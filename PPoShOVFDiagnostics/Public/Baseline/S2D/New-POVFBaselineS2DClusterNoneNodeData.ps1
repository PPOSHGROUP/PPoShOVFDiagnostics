function New-POVFBaselineS2DCluster {
    [CmdletBinding()]
    param (
    
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [System.String[]]
      $Cluster,

      [Parameter(Mandatory=$false)]
      [System.Management.Automation.PSCredential]
      $Credential,

      [Parameter(Mandatory=$true)]
      [System.String]
      [ValidateScript({Test-Path -Path $PSItem -IsValid})]
      $POVFADBaselineFile
  
    )
    begin{
    }
    process{
        #Get Cluster
        #Get Nodes
        #Get Each node Config


    }
  }