Configuration EnableS2D
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        FailoverClusterS2D EnableS2D
        {
            IsSingleInstance = 'Yes'
            Ensure = 'Present'  
        }
    }
}
