<#
.SYNOPSIS
Calculates the requested percentage of the host's memory in megabytes.

.DESCRIPTION
This script calculates the specified percentage of the total physical memory of the host in megabytes.

.PARAMETER percentage
The percentage of the host's memory to calculate.

.EXAMPLE
.\calculate_mem.ps1 -percentage 60
This command will calculate 60% of the host's memory in megabytes.

.NOTES
Author: David Turchak
Date: April 3, 2024
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the percentage of memory to calculate.")]
    [ValidateRange(0, 100)]
    [int]$percentage
)

# Get total physical memory of the host in bytes
$totalMemoryBytes = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory

# Convert total memory from bytes to megabytes
$totalMemoryMB = $totalMemoryBytes / 1MB

# Calculate the requested percentage of memory in megabytes and round to the nearest integer
$requestedMemoryMB = [Math]::Round(($percentage / 100) * $totalMemoryMB)

# Output the result
Write-Output "Requested $percentage% of host memory is: $requestedMemoryMB megabytes"
