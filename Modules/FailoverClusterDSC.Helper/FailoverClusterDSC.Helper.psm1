#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterDSC.Helper.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterDSC.Helper.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

function Test-FCDSCDependency
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (

    )

    if ((Get-WindowsFeature -Name 'Failover-Clustering').InstallState -eq 'Installed')
    {
        # Check if cluster cmdlets are available
        if(!(Get-Module -ListAvailable -Name 'FailoverClusters'))
        {
            Throw ($localizedData.ModuleMissingError -f 'FailoverClusters')
        }
        else
        {
            return $true
        }
    }
    else
    {
        Throw ($localizedData.RoleMissingError -f 'Failover Clustering')
    }
}

function Get-ClusterInformation
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName
    )

    $clusterInfo = @{}
    $cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
    if ($cluster)
    {
        foreach ($property in $cluster.psobject.properties.name)
        { 
            $clusterInfo.Add($property, $cluster.$property)
        }

        $clusterIPAddress = (Get-ClusterResource -Cluster $ClusterName -Name 'Cluster IP Address' -Verbose | Get-ClusterParameter -Name 'Address').Value
        $clusterInfo.Add('IPAddress', $clusterIPAddress)
        $clusterinfo.Add('Node',((Get-ClusterNode -Cluster $ClusterName).Name))

        return $clusterInfo
    }
}

function Test-ClusterParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterName
    )

    $resource = Get-ClusterResourceType -Name $ResourceType -ErrorAction SilentlyContinue

    if ($resource)
    {
        $resourceParameters = $resource | Get-ClusterParameter
        if ($resourceParameters.Name -contains $ParameterName)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        throw $localizedData.ResourceMissingError
    }
}
