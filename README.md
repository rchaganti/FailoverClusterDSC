# FailoverClusterDSC Resource module
*This is not a fork of the xFailoverCluster module. I am adding only the resources that I am developing from scratch to this FailoverClusterDsc module. These resources will follow the HQRM guidelines.*

##Resources in this module

|Resource Name| Description|
|-------------|------------|
|FailoverCluster| Creates a failover cluster.|
|FailoverClusterNode| Adds / removes a node to/from a failover cluster|
|FailoverClusterQuorum| Configures a cluster disk/share/node majority quorum.|
|FailoverClusterCloudWitness| Configures cloud witness for failover cluster.|
|FailoverClusterResourceParameter| Configures a failover cluster resource parameter.|
|FailoverClusterS2D| Enables Storage Spaces Direct in a failover cluster.|
|WaitForFailoverCluster| Waits until a failover cluster becomes available.|
|WaitForFailoverClusterNode| Waits until a node join a failover cluster.|
