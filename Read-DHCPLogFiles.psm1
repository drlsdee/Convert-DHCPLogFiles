function Read-DHCPLog {
    param (
        [Parameter(Mandatory)]
        [string]
        # Path to log file
        $LogFile,

        [Parameter()]
        [switch]
        $V6
    )
    if ($V6) {
        Write-Verbose -Message "reading log file for DHCP V6..."
        $CSVHead = 36
        $HeaderString = "ID","Date","Time","Description","IPv6 Address","Host Name","Error Code","DUID Length","DUID bytes (hex)","UserName","DHCID","Subnet prefix"
    } else {
        Write-Verbose -Message "reading log file for DHCP V4..."
        $CSVHead = 34
        $HeaderString = "ID","Date","Time","Description","IP Address","Host Name","MAC Address","User Name","TransactionID","QResult","Probationtime","CorrelationID","Dhcid","VendorClass(Hex)","VendorClass(ASCII)","UserClass(Hex)","UserClass(ASCII)","RelayAgentInformation","DnsRegError"
    }
        Write-Verbose -Message "Read file:"
        Write-Verbose -Message $LogFile
        $LogContentRaw = Get-Content -Path $LogFile
        Write-Verbose -Message "Table header is:"
        Write-Verbose -Message ($HeaderString -join ",")
        $EndL = $LogContentRaw.Count -1
        $LogContent = $LogContentRaw[$CSVHead..$EndL]
        [array]$TableRaw = ConvertFrom-Csv -InputObject $LogContent -Header $HeaderString
        [array]$TableOut = @()
        $TableRaw.ForEach({
            [datetime]$EventDate = ($_.Date, $_.Time -join " ")
            $EventContent = $_ | Select-Object -Property * -ExcludeProperty Date, Time
            $EventContent | Add-Member -MemberType NoteProperty -Name "DateTime" -Value $EventDate
            $TableOut += $EventContent
        })
        $Out = $TableOut | Sort-Object -Property DateTime -Descending
        return $Out
}

function Read-DHCPLogFiles {
    param (
        [Parameter(Mandatory)]
        # Path to folder with DHCP logs
        [string]
        $LogDir,

        [Parameter()]
        # Read logs for DHCP v6
        [switch]
        $V6
    )
    Write-Verbose -Message "Folder with log files is:"
    Write-Verbose -Message $LogDir
    if ($V6) {
        Write-Verbose -Message "reading logs for DHCP V6..."
        $LogFiles = (Get-ChildItem -Path $LogDir -File -Filter "*.log" | Where-Object {$_.BaseName -match "V6"} ).FullName
    } else {
        Write-Verbose -Message "reading logs for DHCP V4..."
        $LogFiles = (Get-ChildItem -Path $LogDir -File -Filter "*.log" | Where-Object {$_.BaseName -notmatch "V6"} ).FullName
    }
    Write-Verbose -Message "Logfiles found in selected folder:"
    $LogFiles.ForEach({
        Write-Verbose -Message $_
    })

    foreach ($Log in $LogFiles[0]) {
        Read-DHCPLog -LogFile $Log -V6:$V6
    }
}

Export-ModuleMember -Function "Read-DHCPLogFiles"