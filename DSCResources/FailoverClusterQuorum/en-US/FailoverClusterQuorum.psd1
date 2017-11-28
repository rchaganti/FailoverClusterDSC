ConvertFrom-StringData @'
GetQuorum = Get cluster quorum information.
ClusterQuorumExists = Cluster quorum configuration exists as needed. No action needed.
ResourceNotMatching = Cluster quorum resource configuration not matching. It will be updated.
QuorumTypeNotMatching = Cluster quorum type is not matching. It will be updated.
ResourceMandatory = Specifying Resource is mandatory when the QuorumType is set to NodeAndDiskMajority, NodeAndFileShareMajority, DiskOnly
IgnoreResource = Ignoring Resource property as QuorumType is set to NodeMajority.
ResourceMustBeUNC = Resource must be a UNC path when QuorumType is set to NodeAndFileShareMajority.
SetClusterQuorum = Setting cluster quorum configuration.
'@
