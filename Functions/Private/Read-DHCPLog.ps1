function Read-DHCPLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        # Path to log file
        $LogFile,

        [Parameter()]
        [switch]
        $V6
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting the function..."
    if ($V6) {
        Write-Verbose -Message "$myName Reading log file for DHCP V6..."
        [int]$CSVHead = 36
        [string[]]$HeaderString = @(
            'ID',
            'Date',
            'Time',
            'Description',
            'IPv6 Address',
            'Host Name',
            'Error Code',
            'DUID Length',
            'DUID bytes (hex)',
            'UserName',
            'DHCID',
            'Subnet prefix'
        )
    } else {
        Write-Verbose -Message "$myName Reading log file for DHCP V4..."
        [int]$CSVHead = 34
        [string[]]$HeaderString = @(
            'ID',
            'Date',
            'Time',
            'Description',
            'IP Address',
            'Host Name',
            'MAC Address',
            'User Name',
            'TransactionID',
            'QResult',
            'Probationtime',
            'CorrelationID',
            'Dhcid',
            'VendorClass(Hex)',
            'VendorClass(ASCII)',
            'UserClass(Hex)',
            'UserClass(ASCII)',
            'RelayAgentInformation',
            'DnsRegError'
        )
    }
        Write-Verbose -Message "$myName Reading the file: $LogFile"
        [string[]]$LogContentRaw = Get-Content -Path $LogFile
        #$logEncoding = [System.Text.Encoding]::Default
        # In this case, you need to specify the encoding, whereas the Get-Content cmdlet reads even localized strings.
        #[string[]]$LogContentRaw = [System.IO.File]::ReadAllLines($LogFile, $logEncoding)
        Write-Verbose -Message "$myName Table header is: $($HeaderString -join ",")"
        $EndL = $LogContentRaw.Count -1
        $LogContent = $LogContentRaw[$CSVHead..$EndL]
        [array]$TableRaw = ConvertFrom-Csv -InputObject $LogContent -Header $HeaderString
        Write-Verbose -Message "$($TableRaw[0].GetType().FullName)"
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
