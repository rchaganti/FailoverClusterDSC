#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterQuorum.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterQuorum.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the FailoverClusterQuorum resource.

.DESCRIPTION
Gets the current state of the FailoverClusterQuorum resource.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $QuorumType
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            IsSingleInstance = $IsSingleInstance
        }
        
        #Get Quorum information
        Write-Verbose -Message $localizedData.GetQuorum
        $quorumInfo = Get-ClusterInformation -Verbose
        
        $configuration.Add('QuorumType',$quorumInfo.QuorumType)
        $configuration.Add('Resource',$quorumInfo.Resource)
        return $configuration
    }
}

<#
.SYNOPSIS
Sets the FailoverClusterQuorum resource to desired state.

.DESCRIPTION
Sets the FailoverClusterQuorum resource to desired state.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'DiskOnly')]
        [String]
        $QuorumType,

        [Parameter()]
        [String]
        $Resource
    )
    
    if ((($QuorumType -eq 'NodeAndDiskMajority') -or ($QuorumType -eq 'NodeAndFileShareMajority') -or ($QuorumType -eq 'DiskOnly')) -and (!$Resource))
    {
        throw $localizedData.ResourceMandatory
    }

    if ($QuorumType -eq 'NodeMajority' -and $Resource)
    {
        Write-Warning -Message $localizedData.IgnoreResource
    }

    if (($QuorumType -eq 'NodeAndFileShareMajority') -and (-not ([System.uri]$Resource).IsUnc))
    {
        throw $localizedData.ResourceMustBeUNC
    }

    if (Test-FCDSCDependency)
    {
        #Get Quorum information
        Write-Verbose -Message $localizedData.GetQuorum
        $quorumInfo = Get-ClusterInformation -Verbose

        #We can set the quorum directly here. Simply map the QuorumType to a witness type and set it.
        $setParams = @{}

        if ($QuorumType -ne 'NodeMajority')
        {
            $setParams.Add('Resource',$Resource)
        }

        Switch ($QuorumType)
        {
            'NodeMajority' {
                $setParams.Add('NoWitness',$true)   
            }

            'NodeAndDiskMajority' {
                $setParams.Add('DiskWitness', $true)
            }

            'NodeAndFileShareMajority' {
                $setParams.Add('FileShareWitness', $true)
            }

            'DiskOnly' {
                $setParams.Add('DiskOnly', $true)
            }
        }

        Write-Verbose -Message $localizedData.SetClusterQuorum
        Set-ClusterQuorum @setParams -Verbose
    }
}

<#
.SYNOPSIS
Tests if the FailoverClusterQuorum resource is in desired state or not.

.DESCRIPTION
Tests if the FailoverClusterQuorum resource is in desired state or not.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'DiskOnly')]
        [String]
        $QuorumType,

        [Parameter()]
        [String]
        $Resource
    )

    if ((($QuorumType -eq 'NodeAndDiskMajority') -or ($QuorumType -eq 'NodeAndFileShareMajority') -or ($QuorumType -eq 'DiskOnly')) -and (!$Resource))
    {
        throw $localizedData.ResourceMandatory
    }

    if ($QuorumType -eq 'NodeMajority' -and $Resource)
    {
        Write-Warning -Message $localizedData.IgnoreResource
    }

    if (($QuorumType -eq 'NodeAndFileShareMajority') -and (-not ([System.uri]$Resource).IsUnc))
    {
        throw $localizedData.ResourceMustBeUNC
    }

    if (Test-FCDSCDependency)
    {
        #Get Quorum information
        Write-Verbose -Message $localizedData.GetQuorum
        $quorumInfo = Get-ClusterInformation -Verbose
        
        if ($QuorumType -ne $quorumInfo.QuorumType)
        {
            Write-Verbose -Message $localizedData.QuorumTypeNotMatching
            return $false
        }

        if ($Resource -ne $quorumInfo.Resource)
        {
            Write-Verbose -Message $localizedData.ResourceNotMatching
            return $false            
        }

        Write-Verbose -Message $localizedData.ClusterQuorumExists
        return $true
    }
}

Export-ModuleMember -Function *-TargetResource
