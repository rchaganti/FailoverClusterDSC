#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForFailoverClusterNode.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForFailoverClusterNode.psd1 `
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

.PARAMETER NodeName
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
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [String[]]
        $NodeName
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            ClusterName = $ClusterName
            NodeName = $NodeName
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

.PARAMETER NodeName
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

        [Parameter(Mandatory = $true)]
        [String[]]
        $NodeName,

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

        $clusterNodes = Compare-Object -ReferenceObject $clusterInfo.Node -DifferenceObject $NodeName -PassThru
        
        While ((-not $clusterNodes) -or ($count -eq $RetryCount))
        {
            Write-Verbose -Message ($localizedData.WaitingOnRetry -f $count)
            Start-Sleep -Seconds $RetryIntervalSec
            
            $clusterInfo = Get-ClusterInformation -ClusterName $ClusterName
            $clusterNodes = Compare-Object -ReferenceObject $clusterInfo.Node -DifferenceObject $NodeName -PassThru

            $count += 1
        }

        if ($clusterNodes)
        {
            Write-Verbose -Message $localizedData.ClusterNodeAvailable
        }
        else
        {
            throw $localizedData.ClusterNodesNotAvailableAfterTimeout
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

.PARAMETER NodeName
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

        [Parameter(Mandatory = $true)]
        [String[]]
        $NodeName,

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
            if (Compare-Object -ReferenceObject $clusterInfo.Node -DifferenceObject $NodeName -PassThru)
            {
                Write-Verbose -Message $localizedData.ClusterNodeNotAvailable
                return $false
            }
            else
            {
                Write-Verbose -Message $localizedData.ClusterNodeAvailable
                return $true
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
