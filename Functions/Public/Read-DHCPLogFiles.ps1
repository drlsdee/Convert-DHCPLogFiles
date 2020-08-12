function Read-DHCPLogFiles {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory   = $true,
            HelpMessage = 'Specify the path to the directory containing the DHCP server log files on the local or remote file system, e.g. "\\dhcp00\E$\dhcp\logs\" or "C:\Windows\system32\dhcp\logs\".'
        )]
        [Alias('LogDir')]
        # Path to folder with DHCP logs
        [string]
        $Path,

        [Parameter()]
        # Read logs for DHCP v6
        [switch]
        $V6,

        # Log filename pattern for DHCP v4 logs
        [Parameter(
            DontShow    = $true
        )]
        [string]
        $PatternV4  = 'DhcpSrvLog-*.log',

        # Log filename pattern for DHCP v4 logs
        [Parameter(
            DontShow    = $true
        )]
        [string]
        $PatternV6  = 'DhcpV6SrvLog-*.log'
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting the function..."
    $Path = Test-LogDirectory -Path $Path
    if (-not $Path) {
        Write-Error -Category ObjectNotFound `
                    -Message "$myName The directory `"$($Path)`" does not exist! Exiting." `
                    -RecommendedAction "Check the path `"$($Path)`" you specified. It must exist and be a readable directory."
        return
    }

    Write-Verbose -Message "$myName Search for DHCP log files is the directory `"$($Path)`"..."
    if ($V6) {
        Write-Verbose -Message "$myName Reading logs for DHCP V6..."
        $LogFiles = Get-LogFiles -Path $Path -Pattern $PatternV6
    } else {
        Write-Verbose -Message "$myName Reading logs for DHCP V4..."
        $LogFiles = Get-LogFiles -Path $Path -Pattern $PatternV4
    }
    if (-not $LogFiles) {
        Write-Error -Category ObjectNotFound `
                    -Message "$myName The directory `"$($Path)`" does not contain log files! Exiting." `
                    -RecommendedAction "The directory `"$($Path)`" must contain files that match the pattern. Check the hidden parameters `'-PatternV4`' (current value: `"$($PatternV4)`") and `'-PatternV6`' (current value: `"$($PatternV6)`")."
        return
    }

    Write-Verbose -Message "$myName Found $($LogFiles.Count) log files in the selected folder. Set the `"`$InformationPreference`" variable to `"Continue`" if you want to see the filenames."
    $LogFiles.ForEach({
        Write-Information -MessageData "$myName File found: $_"
    })
    $Out = @()
    foreach ($Log in $LogFiles) {
        $Out += Read-DHCPLog -LogFile $Log -V6:$V6
    }
    $Out = $Out | Sort-Object -Property DateTime -Descending
    return $Out
}
