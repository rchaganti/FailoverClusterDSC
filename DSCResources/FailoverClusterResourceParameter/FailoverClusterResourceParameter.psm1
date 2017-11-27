#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'FailoverClusterDSC.Helper' `
                                                     -ChildPath 'FailoverClusterDSC.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterResourceParameter.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename FailoverClusterResourceParameter.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the FailoverClusterResourceParameter resource.

.DESCRIPTION
Gets the current state of the FailoverClusterResourceParameter resource.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Id,

        [Parameter(Mandatory = $true)]
        [String]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterName,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterValue
    )

    if (Test-FCDSCDependency)
    {
        $configuration = @{
            Id = $Id
            ResourceType = $ResourceType
            ParameterName = $ParameterName
            ParameterValue = $ParameterValue
        }
        
        if (Test-ClusterParameter -ResourceType $ResourceType -ParameterName $ParameterName)
        {
            $clusterParameter = Get-ClusterResourceType -Name $ResourceType | Get-ClusterParameter -Name $ParameterName
            if ($clusterParameter.ParameterType -ne 'String')
            {
                $parameterType = $clusterParameter.ParameterType
                $ParameterValue = ($ParameterValue -as ($parameterType -as [type]))
            }
            
            if ($ParameterValue -eq $clusterParameter.Value)
            {
                $configuration.Add('Ensure','Present')
            }
            else
            {
                $configuration.Add('Ensure','Absent')    
            }
        }

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
        [String]
        $Id,

        [Parameter(Mandatory = $true)]
        [String]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterName,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterValue,
        
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    if (Test-FCDSCDependency)
    {
        $params = $PSBoundParameters.Remove('Id')
        if (Test-ClusterParameter -ResourceType $ResourceType -ParameterName $ParameterName)
        {
            if ($Ensure -eq 'Present')
            {
                $paramInfo = Get-ClusterResourceType -Name $ResourceType | Get-ClusterParameter -Name $ParameterName
                if ($paramInfo.ParameterType -ne 'String')
                {
                    $parameterType = $paramInfo.ParameterType
                    $ParameterValue = ($ParameterValue -as ($parameterType -as [type]))
                }

                if ($ParameterValue -ne $paramInfo.Value)
                {
                    Write-Verbose -Message $localizedData.UpdateParameter
                    $null = Get-ClusterResourceType -Name $ResourceType | Set-ClusterParameter -Name $ParameterName -Value $ParameterValue
                }
            }
            else
            {
                Write-Verbose -Message $localizedData.DeleteResourceParameter
                $null = Get-ClusterResourceType -Name $ResourceType | Set-ClusterParameter -Delete -Name $ParameterName -Verbose
            }
        }
        else
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.CreateParameter
                $null = Get-ClusterResourceType -Name $ResourceType | Set-ClusterParameter -Create -Name $ParameterName -Value $convertedParameterValue -Verbose
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
        [String]
        $Id,

        [Parameter(Mandatory = $true)]
        [String]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterName,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterValue,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    if (Test-FCDSCDependency)
    {
        if (Test-ClusterParameter -ResourceType $ResourceType -ParameterName $ParameterName)
        {
            if ($Ensure -eq 'Present')
            {
                $paramInfo = Get-ClusterResourceType -Name $ResourceType | Get-ClusterParameter -Name $ParameterName
                if (-not $paramInfo.IsReadOnly)
                {
                    if ($paramInfo.ParameterType -ne 'String')
                    {
                        $parameterType = $paramInfo.ParameterType
                        $ParameterValue = ($ParameterValue -as ($parameterType -as [type]))
                    }

                    if ($ParameterValue -ne $paramInfo.Value)
                    {
                        Write-Verbose -Message $localizedData.ParameterValueNotMatching
                        return $false
                    }
                    else
                    {
                        Write-Verbose -Message $localizedData.ParameterInDesiredState
                        return $true
                    }
                }
                else
                {
                    throw $localizedData.ParameterCannotBeUpdated    
                }
            }
            else
            {
                Write-Verbose -Message $localizedData.ParameterShouldNotExist
                return $false 
            }
        }
        else
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.ShouldCreateParameter
                return $false
            } 
            else
            {
                Write-Verbose -Message $localizedData.NoParameterNoAction
                return $true
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
