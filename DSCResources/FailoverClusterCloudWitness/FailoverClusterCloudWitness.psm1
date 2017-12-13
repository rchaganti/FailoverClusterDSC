#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterCloudWitness.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterCloudWitness.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the FailoverClusterCloudWitness resource.

.DESCRIPTION
Gets the current state of the FailoverClusterCloudWitness resource.
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
        $AccessKey,

        [Parameter(Mandatory = $true)]
        [String]
        $AccountName
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            IsSingleInstance = $IsSingleInstance
            AccessKey = $AccessKey
        }
        
        #Get Quorum information
        Write-Verbose -Message $localizedData.GetQuorum
        $quorumInfo = Get-ClusterQuorumInformation -Verbose
        
        $configuration.Add('QuorumType',$quorumInfo.QuorumType)
        $configuration.Add('AccountName',$quorumInfo.Resource.AccountName)
        $configuration.Add('Endpoint',$quorumInfo.Resource.EndpointInfo)
        return $configuration
    }
}

<#
.SYNOPSIS
Sets the FailoverClusterResourceParameter resource to desired state.

.DESCRIPTION
Sets the FailoverClusterResourceParameter resource to desired state.
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
        [String]
        $AccessKey,

        [Parameter(Mandatory = $true)]
        [String]
        $AccountName,

        [Parameter()]
        [String]
        $Endpoint = 'core.windows.net',

        [Parameter()]
        [bool]
        $Force,
        
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    if (Test-FCDSCDependency)
    {
        $params = @{
            AccountName = $AccountName
            AccessKey = $AccessKey
            Endpoint = $Endpoint
            CloudWitness = $true
        }

        if ($Force)
        {
            $forceUpdate = $true
        }
        else
        {
            #Get Quorum information
            $quorumInfo = Get-ClusterQuorumInformation -Verbose
            
            if ($quorumInfo.QuorumType -eq 'CloudWitness')
            {
                if ($Ensure -eq 'Present')
                {
                    if ($quorumInfo.Resource.EndpointInfo -ne $Endpoint)
                    {
                        $forceUpdate = $true
                    }

                    if ($quorumInfo.AccountName -ne $AccountName)
                    {
                        $forceUpdate = $true
                    }
                }
                else
                {
                    Write-Verbose -Message $localizedData.RemoveCloudWitness
                    Set-ClusterQuorum -NoWitness -Verbose    
                }
            }
            else
            {
                if ($Ensure -eq 'Present')
                {
                    Write-Verbose -Message $localizedData.CreateCloudWitness
                    $forceUpdate = $true
                }
            }
        }

        if ($forceUpdate)
        {
            Write-Verbose -Message $localizedData.ForcingUpdate
            Set-ClusterQuorum @params -Verbose
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

        [Parameter(Mandatory = $true)]
        [String]
        $AccessKey,

        [Parameter(Mandatory = $true)]
        [String]
        $AccountName,

        [Parameter()]
        [String]
        $Endpoint = 'core.windows.net',

        [Parameter()]
        [bool]
        $Force,
        
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    if (Test-FCDSCDependency)
    {
        if ($Force)
        {
            Write-Verbose -Message $localizedData.ForceSpecifiedShouldUpdate
            return $false
        }
        else
        {
            #Get Quorum information
            Write-Verbose -Message $localizedData.GetQuorum
            $quorumInfo = Get-ClusterQuorumInformation -Verbose
            
            if ($quorumInfo.QuorumType -eq 'CloudWitness')
            {
                Write-Verbose -Message $localizedData.CloudWitnessQuorumFound
                if ($Ensure -eq 'Present')
                {
                    if ($quorumInfo.Resource.EndpointInfo -ne $Endpoint)
                    {
                        Write-Verbose -Message $localizedData.EndpointNotMatching
                        return $false
                    }

                    if ($quorumInfo.Resource.AccountName -ne $AccountName)
                    {
                        Write-Verbose -Message $localizedData.AccountNameNotMatching
                        return $false
                    }

                    Write-Verbose -Message $localizedData.CloudWitnessExistsNoAction
                    return $true
                }
                else
                {
                    Write-Verbose -Message $localizedData.CloudWitnessShouldNotExist
                    return $false
                }
            }
            else
            {
                if ($Ensure -eq 'Present')
                {
                    Write-Verbose -Message $localizedData.CloudWitnessShouldExist
                    return $false
                }
                else
                {
                    Write-Verbose -Message $localizedData.CloudWitessDoesNotExistNoAction
                    return $true
                }
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
