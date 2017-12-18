Configuration ClusterCloudWitness
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $AccessKey,

        [Parameter(Mandatory = $true)]
        [String]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        FailoverClusterCloudWitness FCClusterCloudWitness
        {
            IsSingleInstance = 'Yes'
            AccessKey = $AccessKey
            AccountName = $AccountName        
            PsDscRunAsCredential = $ClusterAdminCredential            
        }
    }
}
