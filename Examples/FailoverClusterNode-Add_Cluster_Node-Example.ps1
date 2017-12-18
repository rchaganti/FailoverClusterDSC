Configuration AddClusterNode
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        FailoverClusterNode FCClusterNode
        {
            ClusterName = $ClusterName
            NodeName =  $NodeName
            PsDscRunAsCredential = $ClusterAdminCredential
            Ensure = 'Present'
        }
    }
}
