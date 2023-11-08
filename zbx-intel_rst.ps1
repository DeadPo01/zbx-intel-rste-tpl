Param (    
    [ValidateSet("rst.getcli","rst.info")][Parameter(Position=0, Mandatory=$False)][string]$action,    
    [ValidateSet("vol","pd")][Parameter(Position=1, Mandatory=$False)][string]$dev,
    [ValidateSet("lld","status")][Parameter(Position=2, Mandatory=$False)][string]$devaction,
    [Parameter(Position=3, Mandatory=$False)][string]$devid
)


$clipath = "$env:SystemDrive:\zabbix\scripts\rst\"


$rst_txt = $clipath+"RST.txt"

Function Get-Cli() {
    if (!(Test-Path $rst_txt)){
        $drvver = (Get-WmiObject Win32_PnPSignedDriver -Filter "Manufacturer LIKE 'Intel%' and DeviceName LIKE '%RAID%'" | select DeviceName,DriverVersion).DriverVersion.Split(".")        

        Switch ($drvver[0]+$drvver[1]+$drvver[2]) {
        "170" {$cli = "13_16_rstcli64.exe"}
        "430" {$cli = "4.3.0_rstcli64.exe"}
        "450" {$cli = "4.5.0_rstcli64.exe"}
        "460" {$cli = "4.6.0_rstcli64.exe"}
        "500" {$cli = "5.0.0_rstcli64.exe"}
        "503" {$cli = "5.0.3_rstcli64.exe"}
        "530" {$cli = "5.3.0_rstcli64.exe"}
        "550" {$cli = "5.5.0_rstcli64.exe"}
        "560" {$cli = "5.6.0_rstcli64.exe"}
        "610" {$cli = "6.1.0_IntelVROCCli.exe"}    
        Default {$cli = "rstcli64.exe"}
        }
        $cli > $rst_txt                
    }
$cli = Get-Content $rst_txt
Write-Host $cli
}

Function Get-RST-info() {     
    if (!(Test-Path $rst_txt)){
        Get-Cli     
        $cli = Get-Content $rst_txt       
    } else {
        $cli = Get-Content $rst_txt
    }        
    #$devinfo = & "$clipath$cli" "-I"
    $devinfo = Get-Content "C:\zabbix\scripts\rst\test.txt"

    if ($dev -eq "vol") {
        $dev_first_line = $devinfo | Select-String -Pattern "--VOLUME INFORMATION--" | Select-Object -ExpandProperty LineNumber
        $dev_last_line = $devinfo | Select-String -Pattern "--END DEVICE INFORMATION--" | Select-Object -ExpandProperty LineNumber    
        $volinfo = $devinfo | Select-Object -Skip ($dev_first_line) -First (($dev_last_line-$dev_first_line-3))
        $volinfo = $volinfo -replace '\s',''
        foreach ($line in $volinfo){
            if ($line -eq "") { continue }
            $line = $line.Split(":")
            # Write-Host "First:" $line[0] ", second: " $line[1]
            if ($line[0] -contains "Name"){
                $volname = $line[1]
                [array]$json += @{ $volname = @{
                $line[0] = $volname
                }}                         
            } else {
                $json.$volname.add($line[0], $line[1])
            }
        }

        Switch ($devaction){
        "lld" { ConvertTo-Json $json }
        "status" { $json.$devid."State" }
        Default {Write-Host "Error in params or unknown dev ID!" }
        }
    }
    
    if ($dev -eq "pd") {
    $dev_first_line = $devinfo | Select-String -Pattern "--END DEVICE INFORMATION--" | Select-Object -ExpandProperty LineNumber
    $pdinfo = $devinfo | Select-Object -Skip ($dev_first_line)
    $pdinfo = $pdinfo -replace '\s',''
        foreach ($line in $pdinfo) {
            if ($line -eq "") { continue }                  
            $line = $line.Split(":")
            
            if ($line[0] -contains "ID"){
                $pdid = $line[1]
                [array]$json += @{ $pdid = @{
                $line[0] = $pdid
                }}                         
            } else {
                $json.$pdid.add($line[0], $line[1])
            }
        }

        Switch ($devaction){
        "lld" { ConvertTo-Json $json }
        "status" { $json.$devid."State" }
        Default {Write-Host "Error in params or unknown dev ID!" }
        }
    }
}


Switch ($action){
"rst.getcli" { Get-Cli }
"rst.info" { Get-RST-info }
Default { Write-host "ERROR: Wrong first argument: use 'rst.getcli' or 'rst.info'"}
}