Configuration ClusterFileShareQuorum
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $Resource,

        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        FailoverClusterQuorum FCClusterQuorum
        {
            IsSingleInstance = 'Yes'
            QuorumType = 'NodeAndFileShareMajority'
            Resource = '\\sofs\quorumshare'
            PsDscRunAsCredential = $ClusterAdminCredential            
        }
    }
}
