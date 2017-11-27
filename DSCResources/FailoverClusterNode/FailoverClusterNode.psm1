#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterNode.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterNode.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the FailoverClusterNode resource.

.DESCRIPTION
Gets the current state of the FailoverClusterNode resource.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            NodeName = $NodeName
            ClusterName = $ClusterName
        }

        $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName

        if ($clusterInfo)
        {
            if ($clusterInfo.Node -contains $NodeName)
            {
                $configuration.Add('Ensure','Present')
            }
            else
            {
                $configuration.Add('Ensure','Absent')
            }
        }
        else
        {
            $configuration.Add('Ensure','Absent')    
        }
        return $configuration
    }
}

<#
.SYNOPSIS
Sets the FailoverClusterNode resource to desired state.

.DESCRIPTION
Sets the FailoverClusterNode resource to desired state.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $NodeName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    if (Test-FCDSCDependency)
    {
        $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName

        if ($clusterInfo)
        {
            if ($Ensure -eq 'Present')
            {
                if ($clusterInfo.Node -notcontains $NodeName)
                {
                    Write-Verbose -Message $localizedData.AddClusterNode
                    Add-ClusterNode -Name $NodeName -Cluster $ClusterName -Verbose
                }
            }
            else
            {
                if ($clusterInfo.Node -contains $NodeName)
                {
                    if ($clusterInfo.Node.Count -eq 1)
                    {
                        Write-Warning -Message $localizedData.CannotRemoveNode
                    }
                    else
                    {
                        Write-Verbose -Message $localizedData.RemoveClusterNode                    
                        Remove-ClusterNOde -Name $NodeName -Cluster $ClusterName -CleanupDisks -Force
                    }
                }
            }   
        }
    }
}

<#
.SYNOPSIS
Tests if the FailoverClusterNode resource is in desired state or not.

.DESCRIPTION
Tests if the FailoverClusterNode resource is in desired state or not.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $NodeName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    if (Test-FCDSCDependency)
    {
        $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName

        if ($clusterInfo)
        {
            Write-Verbose -Message $localizedData.ClusterExists
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.CheckIfNodeExists
                if ($clusterInfo.Node -notcontains $NodeName)
                {
                    Write-Verbose -Message $localizedData.NodeIsNotInCluster
                    return $false
                }

                Write-Verbose -Message $localizedData.NodeExistsInCluster
                return $true
            }
            else
            {
                Write-Verbose -Message $localizedData.NodeShouldNotExistt
                return $false
            }    
        }
        else
        {
            throw $localizedData.ClusterDoesNotExist   
        }
    }
}

Export-ModuleMember -Function *-TargetResource
