#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterS2D.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterS2D.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the FailoverClusterS2D resource.

.DESCRIPTION
Gets the current state of the FailoverClusterS2D resource.
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
        $IsSingleInstance
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            IsSingleInstance = $IsSingleInstance
        }
        
        #Get Quorum information
        Write-Verbose -Message $localizedData.GetClusterS2D
        $s2dInfo = Get-ClusterS2D -Verbose
        $configuration.Add('CachePageSizeKBytes', $s2dInfo.CachePageSizeKBytes)
        $configuration.Add('CacheMetadataReserveBytes', $s2dInfo.CacheMetadataReserveBytes)
        $configuration.Add('CacheState', $s2dInfo.CacheState)
        $configuration.Add('CacheDeviceModel', $s2dInfo.CacheDeviceModel)    
        $configuration.Add('CacheModeSSD',$s2dInfo.CacheModeSSD)
        $configuration.Add('CacheModeHDD',$s2dInfo.CacheModeHDD)

        if ($s2dInfo.State -eq 'Enabled')
        {
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
Sets the FailoverClusterS2D resource to desired state.

.DESCRIPTION
Sets the FailoverClusterS2D resource to desired state.
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

        [Parameter()]
        [String]
        $PoolFriendlyName,

        [Parameter()]
        [ValidateSet('8','16','32','64')]
        [uint32]
        $CachePageSizeKBytes = 16,

        [Parameter()]
        [uint64]
        $CacheMetadataReserveBytes,

        [Parameter()]
        [ValidateSet('Enabled','Disabled')]
        [String]
        $CacheState = 'Enabled',

        [Parameter()]
        [String]
        $CacheDeviceModel,

        [Parameter()]
        [String]
        $XML,

        [Parameter()]
        [Boolean]
        $AutoConfig = $false,

        [Parameter()]
        [Boolean]
        $SkipEligibilityChecks = $false,
        
        [Parameter()]
        [Boolean]
        $CleanupCache = $false,  

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present' 
    )

    if ($CacheDeviceModel -and $XML)
    {
        throw $localizedData.XMLAndCacheDeviceModel
    }

    if ($Ensure -eq 'Present' -and $CleanupCache)
    {
        Write-Warning -Message $lcoalizedData.IgnoreCleanUpCache
    }

    if (Test-FCDSCDependency)
    {
        $s2dInfo = Get-ClusterS2D -Verbose

        if ($s2dInfo.State -ne 'Enabled')
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.EnableS2D
                $params = @{
                    AutoConfig = $AutoConfig
                    SkipEligibilityChecks = $SkipEligibilityChecks
                    CacheState = $CacheState
                    CachePageSizeKBytes = $CachePageSizeKBytes
                }

                if ($PoolFriendlyName)
                {
                    $params.Add('PoolFriendlyName', $PoolFriendlyName)
                }

                if ($XML)
                {
                    $params.Add('XML', $XML)
                }

                if ($CacheDeviceModel)
                {
                    $params.Add('CacheDeviceModel', $CacheDeviceModel)
                }

                if ($CacheMetadataReserveBytes)
                {
                    $params.Add('CacheMetadataReserveBytes', $CacheMetadataReserveBytes)
                }

                $null = Enable-ClusterS2D @params -Verbose -Confirm:$false
            }
        }
        else
        {
            if ($Ensure -eq 'Present')
            {
                if ($s2dInfo.CacheState -ne $CacheState)
                {
                    Write-Verbose -Message $lcoalizedData.UpdateCacheState
                    Set-ClusterS2D -CacheState $CacheState -Verbose
                }
            }
            else
            {
                Write-Verbose -Message $localizedData.DisableClusterS2D
                Disable-ClusterS2D -CleanupCache $CleanupCache -Confirm:$false    
            }
        }
    }
}

<#
.SYNOPSIS
Tests if the FailoverClusterResourceParameter resource is in desired state or not.

.DESCRIPTION
Tests if the FailoverClusterResourceParameter resource is in desired state or not.
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

        [Parameter()]
        [String]
        $PoolFriendlyName,

        [Parameter()]
        [ValidateSet('8','16','32','64')]
        [uint32]
        $CachePageSizeKBytes = 16,

        [Parameter()]
        [uint64]
        $CacheMetadataReserveBytes,

        [Parameter()]
        [ValidateSet('Enabled','Disabled')]
        [String]
        $CacheState = 'Enabled',

        [Parameter()]
        [String]
        $CacheDeviceModel,

        [Parameter()]
        [String]
        $XML,

        [Parameter()]
        [Boolean]
        $AutoConfig = $false,

        [Parameter()]
        [Boolean]
        $SkipEligibilityChecks = $false,

        [Parameter()]
        [Boolean]
        $CleanupCache = $false,        

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'       
    )

    if ($CacheDeviceModel -and $XML)
    {
        throw $localizedData.XMLAndCacheDeviceModel
    }

    if (Test-FCDSCDependency)
    {
        $s2dInfo = Get-ClusterS2D -Verbose

        if ($Ensure -eq 'Present')
        {
            if ($s2dInfo.State -ne 'Enabled')
            {
                Write-Verbose -Message $localizedData.S2DWillBeEnabled
                return $false
            }

            if ($s2dInfo.CacheState -ne $CacheState)
            {
                Write-Verbose -Message $lcoalizedData.CacheStateDifferent
                return $false
            }

            if ($s2dInfo.CacheDeviceModel -ne $CacheDeviceModel)
            {
                Write-Warning -Message $localizedData.CacheDeviceModelCannotBeChanged
            }

            if ($s2dInfo.CachePageSizeKBytes -ne $CachePageSizeKBytes)
            {
                Write-Warning -Message $localizedData.CachePageSizeKBytesCannotBeChanged
            }

            if ($s2dInfo.CacheMetadataReserveBytes -ne $CacheMetadataReserveBytes)
            {
                Write-Warning -Message $localizedData.CacheMetadataReserveBytesCannotBeChanged
            }

            Write-Verbose -Message $localizedData.S2DExistsNoAction
            return $true
        }
        else
        {
            if ($s2dInfo.State -ne 'Enabled')
            {
                Write-Verbose -Message $localizedData.S2DShouldNotExist
                return $false                
            }
            else
            {
                Write-Verbose -Message $localizedData.S2DDoesNotExistNoAction
                return $true                   
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
