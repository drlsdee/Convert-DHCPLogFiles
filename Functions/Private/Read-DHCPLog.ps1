function Read-DHCPLog {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory   = $true
        )]
        [string]
        # Path to log file
        $Path,

        # Encoding
        [Parameter()]
        [ValidateSet(
            'ASCII',
            'BigEndianUnicode',
            'Default',
            'Unicode',
            'UTF32',
            'UTF7',
            'UTF8'
        )]
        [string]
        $Encoding,

        # Read logs for DHCP v6
        [Parameter()]
        [switch]
        $V6,

        # Use original headers from log files
        [Parameter()]
        [switch]
        $OriginalHeaders
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    [string]$psDataFile = [System.IO.Path]::ChangeExtension($PSCommandPath, 'psd1')
    [hashtable]$psDataTable = Import-PowerShellDataFile -Path $psDataFile
    Write-Verbose -Message "$myName Starting the function..."
    if ($V6) {
        Write-Verbose -Message "$myName Assuming that the log file `"$Path`" is DHCPv6 log."
        [int]$logHeaderIndex    = 35
        [string[]]$logHeaders   = $psDataTable.V6
    }
    else {
        Write-Verbose -Message "$myName Assuming that the log file `"$Path`" is DHCPv4 log."
        [int]$logHeaderIndex    = 33
        [string[]]$logHeaders   = $psDataTable.V6
    }
    Write-Verbose -Message "$myName Reading the file `"$Path`" with selected encoding: $Encoding"
    [string[]]$logContentRaw    = Get-Content -Path $Path -Encoding $Encoding

    if (-not $logContentRaw) {
        Write-Warning -Message "$myName The file `"$Path`" is empty! Exiting."
        return
    }

    if ($logContentRaw.Count -lt $logHeaderIndex) {
        Write-Warning -Message "$myName The file `"$Path`" contains less than $($logHeaderIndex) lines! Exiting."
        return
    }

    [string]$logHeaderString    = $logContentRaw[$logHeaderIndex]
    if (
        [string]::IsNullOrEmpty($logHeaderString) -or `
        [string]::IsNullOrWhiteSpace($logHeaderString) -or `
        ($logHeaderString -notmatch ',')
    )
    {
        Write-Warning -Message "$myName The $($logHeaderIndex)th line in the file `"$Path`" does not contain header! Exiting."
        return
    }

    # Use original log headers from the file or use english headers
    if ($OriginalHeaders) {
        #   Trim unnecessary whitespaces around the column headings.
        [string[]]$logHeaderSplit   = $logHeaderString.Split(',').ForEach({
            $_.Trim(' .')
        })
        $logHeaderString            = $logHeaderSplit -join ','
    }
    else {
        [string[]]$logHeaderSplit   = $logHeaders
        $logHeaderString            = $logHeaders -join ','
    }
    Write-Verbose -Message "$myName The log header: $logHeaderString"

    [int]$logLineFirst          = $logHeaderIndex + 1
    [int]$logLineLast           = $logContentRaw.Count - 1
    [string[]]$logContentBody   = $logContentRaw[$logLineFirst..$logLineLast].Where({$_})
    if (-not $logContentBody) {
        Write-Warning -Message "$myName The file `"$Path`" does not contain records! Exiting."
        return
    }
<#
    For a strange reason, the last column headers are missing from the DHCP log files. At least on my instances.
    if (
        ($logHeaderSplit.Count -ne $logContentBody[0].Split(',').Count) -and `
        (-not $V6)
    )
    {
        Write-Warning -Message "$myName The header of the logfile `"$Path`" does not match the contents of the log entries! Headers count: $($logHeaderSplit.Count); fields count: $($logContentBody[0].Split(',').Count) Exiting."
        return
    }
#>
    [PSCustomObject[]]$logContentTable    = ConvertFrom-Csv -InputObject $logContentBody -Header $logHeaderSplit -Delimiter ','
    Write-Verbose -Message "$myName Found $($logContentTable.Count) entries in the log file: $Path"

    # Converting the "Date" and "Time" columns into single timestamp
    Write-Verbose -Message "$myName Converting the `"Date`" and `"Time`" columns into single timestamp. For extended information set the `"`$InformationPreference`" variable to `"Continue`"."
    [PSCustomObject[]]$tableToReturn    = @()
    [string]$dateKey    = $logContentTable[5].PSObject.Properties.Name[1]
    [string]$timeKey    = $logContentTable[5].PSObject.Properties.Name[2]
    Write-Information -MessageData "$myName The key containing the date: `"$($dateKey)`"; the key containing the time: `"$($timeKey)`"."
    $logContentTable.ForEach({
        [PSCustomObject]$entryCurrent   = $_
        [string]$dateTimeStringRaw      = "$($entryCurrent.$dateKey) $($entryCurrent.$timeKey)"
        [datetime]$dateTimeObject       = [datetime]::Parse($dateTimeStringRaw)
        [string]$dateTimeStamp          = $dateTimeObject.ToString('yyyy-MM-ddTHH:mm:ss.fffffffK')
        Write-Information -MessageData "$myName The timestamp string: $dateTimeStamp"
        [PSCustomObject]$entryConverted = $entryCurrent | Select-Object -Property * -ExcludeProperty @($dateKey, $timeKey)
        Write-Information -MessageData "$myName Replacing the separate keys with timestamp string and adding the new object to the output."
        $entryConverted | Add-Member -MemberType NoteProperty -Name 'DateTime' -Value $dateTimeStamp
        $tableToReturn += $entryConverted
    })
    return $tableToReturn
}
