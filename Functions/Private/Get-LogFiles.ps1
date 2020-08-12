function Get-LogFiles {
    [CmdletBinding()]
    param (
        # Path to the folder containing log files
        [Parameter()]
        [string]
        $Path,

        # Log filename pattern for DHCP v4 logs
        [Parameter()]
        [string]
        $Pattern
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting the function..."
    Write-Verbose -Message "$myName Looking for DHCP log files matching the pattern `"$($Pattern)`" in the folder `"$($Path)`"..."
    [string[]]$logFiles          = [System.IO.Directory]::EnumerateFiles($Path, $Pattern)
    if (-not $logFiles) {
        Write-Warning -Message "$myName The directory `"$($Path)`" does not contain files mathcing the pattern `"$($Pattern)`"!"
        return
    }
    Write-Verbose -Message "$myName Found $($logFiles.Count) log files. Returning."
    return $logFiles
}