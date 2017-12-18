#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForFailoverCluster.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForFailoverCluster.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ClusterName
Parameter description

.PARAMETER StaticAddress
Parameter description
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            ClusterName = $ClusterName
        }

        return $configuration
    }
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ClusterName
Parameter description

.PARAMETER StaticAddress
Parameter description

.PARAMETER RetryIntervalSec
Parameter description

.PARAMETER RetryCount
Parameter description
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ClusterName,

        [Parameter()]
        [UInt32]
        $RetryIntervalSec = 15,

        [Parameter()]
        [UInt32]
        $RetryCount = 40  
    )

    if (Test-FCDSCDependency)
    {
        $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName
        $count = 1

        While ((-not $clusterInfo) -or ($count -eq $RetryCount))
        {
            Write-Verbose -Message ($localizedData.WaitingOnRetry -f $count)
            Start-Sleep -Seconds $RetryIntervalSec
            
            $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName
            $count += 1
        }

        if ($clusterInfo)
        {
            Write-Verbose -Message $localizedData.ClusterAvailable
        }
        else
        {
            throw $localizedData.ClusterNotAvailableAfterTimeout
        }
    }
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ClusterName
Parameter description

.PARAMETER StaticAddress
Parameter description

.PARAMETER RetryIntervalSec
Parameter description

.PARAMETER RetryCount
Parameter description
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

        [Parameter()]
        [UInt32]
        $RetryIntervalSec = 15,

        [Parameter()]
        [UInt32]
        $RetryCount = 40        
    )

    if (Test-FCDSCDependency)
    {
        $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName
        if ($clusterInfo)
        {
            Write-Verbose -Message ($localizedData.ClusterExists -f $ClusterName)
            return $true
        }
        else
        {
            Write-Verbose -Message ($localizedData.ClusterDoesNotExist -f $ClusterName)
            return $false
        }
    }
}

Export-ModuleMember -Function *-TargetResource
