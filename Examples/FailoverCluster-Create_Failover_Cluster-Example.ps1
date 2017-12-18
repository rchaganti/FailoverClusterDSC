Configuration CreateCluster
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $ClusterIPAddress,
        
        [Parameter(Mandatory = $true)]
        [String[]]
        $IgnoreNetwork,

        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        FailoverCluster FCCluster
        {
            ClusterName = $ClusterName
            StaticAddress = $ClusterIPAddress
            IgnoreNetwork = $IgnoreNetwork
            PsDscRunAsCredential = $ClusterAdminCredential
            Ensure = 'Present'
        }
    }
}
