Configuration ClusterMigrationExcludeNetworks
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $ExcludeNetworks,

        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        FailoverClusterResourceParameter ExcludeLMNetwork
        {
            Id = 'ExcludeHostMgmtLM'
            ResourceType = 'Virtual Machine'
            ParameterName = 'MigrationExcludeNetworks'
            ParameterValue = $ExcludeNetworks
            PsDscRunAsCredential = $ClusterAdminCredential
            Ensure = 'Present'
        }
    }
}
