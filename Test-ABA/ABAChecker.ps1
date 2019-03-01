param(
    [string]$RoutingNumber,
    [switch]$LoadFunctions
)

Function Test-ABA {
    param($RoutingNumber)
    $urlABARoutingNumberVerify = "https://www.routingnumbers.info/api/data.json?rn="
    (Invoke-WebRequest -Uri ($urlABARoutingNumberVerify + $RoutingNumber)).Content | ConvertFrom-Json
}

if ($RoutingNumber) {
    Test-ABA -RoutingNumber $RoutingNumber
    return
} elseif ($LoadFunctions) {
    return
} else {
    . "$(Split-Path -Parent $PSCommandPath)\ABAChecker-GUI.ps1"
}
