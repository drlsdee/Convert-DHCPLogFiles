function Test-LogDirectory {
    [CmdletBinding()]
    param (
        # Path to the folder containing log files
        [Parameter()]
        [string]
        $Path
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting the function..."
    $Path = [System.IO.Path]::GetFullPath($Path)
    Write-Verbose -Message "$myName The full path resolved as `"$($Path)`". Continue."
    if ([System.IO.Directory]::Exists($Path)) {
        Write-Verbose -Message "$myName The directory `"$($Path)`" exists. Returning."
        return $Path
    }

    if ([System.IO.File]::Exists($Path)) {
        [string]$parentPath = [System.IO.Path]::GetDirectoryName($Path)
        Write-Warning -Message "$myName The file `"$($Path)`" found but should be a directory! Returning the directory name: $parentPath"
        return $parentPath
    }

    Write-Warning -Message "$myName No folder or file found in the specified path `"$($Path)`"! Exiting."
    return
}