#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverCluster.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverCluster.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the FailoverCluster resource.

.DESCRIPTION
Gets the current state of the FailoverCluster resource.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String]
        $StaticAddress
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            ClusterName = $ClusterName
            StaticAddress = $StaticAddress
        }

        $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName -Verbose

        if ($clusterInfo)
        {
            $configuration.Add('AdministrativeAccessPoint', $clusterInfo.AdministrativeAccessPoint)
            $configuration.Add('Ensure','Present')
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
Sets the FailoverCluster resource to desired state.

.DESCRIPTION
Sets the FailoverCluster resource to desired state.
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
        $StaticAddress,

        [Parameter()]
        [Boolean]
        $NoStorage = $true,

        [Parameter()]
        [ValidateSet('ActiveDirectoryAndDns','None','Dns')]
        [String]
        $AdministrativeAccessPoint = 'ActiveDirectoryAndDns',

        [Parameter()]
        [String[]]
        $IgnoreNetwork,
        
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
                #First, Check if we need to update the cluster IP Address
                if ($StaticAddress -ne $clusterInfo.IPAddress)
                {
                    Write-Warning -Message $localizedData.UpdateIPAddress
                    Get-ClusterResource -Cluster $ClusterName -Name 'Cluster IP Address' -Verbose | Set-ClusterParameter -Name 'Address' -Value $StaticAddress
                }
            }
            else
            {
                Write-Verbose -Message $localizedData.RemoveCluster
                $paramerters = @{
                    Cluster = $ClusterName
                }

                if ($clusterInfo.AdministrativeAccessPoint -eq 'ActiveDirectoryAndDns')
                {
                    $parameters.Add('CleanUpAD',$true)
                }                
                Remove-Cluster @parameters -Force -Verbose
            }   
        }
        else
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.CreateCluster
                $paramerters = @{
                    Name = $ClusterName
                    StaticAddress = $StaticAddress
                    NoStorage = $NoStorage
                }

                if ($IgnoreNetwork)
                {
                    $paramerters.Add('IgnoreNetwork', $IgnoreNetwork)
                }

                $null = New-Cluster @paramerters -Verbose
            }  
        }
    }
}

<#
.SYNOPSIS
Tests if the FailoverCluster resource is in desired state or not.

.DESCRIPTION
Tests if the FailoverCluster resource is in desired state or not.
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
        $StaticAddress,

        [Parameter()]
        [Boolean]
        $NoStorage = $true,    

        [Parameter()]
        [ValidateSet('ActiveDirectoryAndDns','None','Dns')]
        [String]
        $AdministrativeAccessPoint = 'ActiveDirectoryAndDns',

        [Parameter()]
        [String[]]
        $IgnoreNetwork,

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
                Write-Verbose -Message $localizedData.CheckClusterProperties

                #Check if cluster IP address matches are not
                if ($StaticAddress -ne $clusterInfo.IPAddress)
                {
                    Write-Verbose -Message $localizedData.IPNotMatching
                    return $false
                }

                #Check AdministrativeAccessPoint
                if ($AdministrativeAccessPoint -ne $clusterInfo.AdministrativeAccessPoint)
                {
                    Write-Warning -Message $localizedData.AAPointNotMatching
                }

                Write-Verbose -Message $localizedData.ClusterExistsAsNeeded
                return $true
            }
            else
            {
                Write-Verbose -Message $localizedData.ClusterShouldNotExist
                return $false
            }    
        }
        else
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.ClusterShouldExist
                return $false
            }
            else
            {
                Write-Verbose -Message $localizedData.ClusterDoesNotExistNoAction
                return $true    
            }    
        }
    }
}

Export-ModuleMember -Function *-TargetResource
