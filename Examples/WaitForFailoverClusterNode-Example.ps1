Configuration WaitForFailoverClusterNode
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [pscredential]
        $ClusterAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName FailoverClusterDSC -ModuleVersion 1.0.0.0

    Node $AllNodes.NodeName
    {
        WaitForFailoverClusterNode WaitForFClusterNode
        {
            ClusterName = $ClusterName
            NodeName = @('S2D3N02','S2D3N03')
            RetryIntervalSec = 10
            RetryCount = 10
        }
    }
}
