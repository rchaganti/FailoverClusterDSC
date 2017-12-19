$configData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            thumbprint = '25A1359A27FB3F2D562D7508D98E7189F2A1F1B0'
            CertificateFile = 'C:\PublicKeys\S2D4N01.cer'
            PsDscAllowDomainUser = $true
        }
    )
}

Configuration CreateS2DCluster
{
    param
    (
        [Parameter(Mandatory = $true)]
        [pscredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [String[]]
        $ParticipantNodes,

        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $StaticAddress,

        [Parameter(Mandatory = $true)]
        [String[]]
        $IgnoreNetworks,

        [Parameter(Mandatory = $true)]
        [String]
        $QuorumResource,

        [Parameter(Mandatory = $true)]
        [String]
        $QuorumType
        
    )

    Import-DscResource -ModuleName FailoverClusterDsc

    Node $AllNodes.NodeName
    {
        FailoverCluster CreateCluster
        {
            ClusterName = $ClusterName
            StaticAddress = $StaticAddress
            NoStorage = $true
            IgnoreNetwork = $IgnoreNetworks
            Ensure = 'Present'
            PsDscRunAsCredential = $Credential
        }

        WaitForFailoverCluster WaitForCluster
        {
            ClusterName = $ClusterName
            PsDscRunAsCredential = $Credential
        }

        Foreach ($node in $ParticipantNodes)
        {
            FailoverClusterNode $node
            {
                NodeName = $node
                ClusterName = $ClusterName
                PsDscRunAsCredential = $Credential
                Ensure = 'Present'
            }
        }

        FailoverClusterQuorum FileShareQuorum
        {
            IsSingleInstance = 'Yes'
            QuorumType = $QuorumType
            Resource = $QuorumResource
        }

        FailoverClusterS2D EnableS2D
        {
            IsSingleInstance = 'yes'
            Ensure = 'Present'
        }
    }
}

CreateS2DCluster -Credential (Get-Credential) -ConfigurationData $configData `
                                           -QuorumType 'NodeAndFileShareMajority' `
                                           -QuorumResource '\\sofs\share' `
                                           -ClusterName 'S2D4NCluster' `
                                           -StaticAddress '172.16.102.45' `
                                           -IgnoreNetworks @('172.16.103.0/24','172.16.104.0/24') `
                                           -ParticipantNodes @('S2D4N02','S2D4N03','S2D4N04')
