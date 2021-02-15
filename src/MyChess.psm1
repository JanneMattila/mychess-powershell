$ErrorActionPreference = "Stop"

. $PSScriptRoot\Classes.ps1

function Connect-MyChess
(
    [Parameter(HelpMessage = "My Chess environment")] 
    [ValidateSet("Development", "Production")]
    [string] 
    $Environment = "Production"
) {
    $environments = @{ 
        "Development" = @{
            Address    = "https://azfun-mychess-z67p7cxye4n5q.azurewebsites.net";
            AppId      = "f4617c7d-a6c2-444a-b7c0-a9942dd88b3c";
            ResourceId = "9ea259c1-4a8c-489a-86d5-54fa90dc3fd3"
        };
        "Production"  = @{
            Address    = "https://azfun-mychess-dvcszl3mb4xx4.azurewebsites.net";
            AppId      = "6a824c79-d2d8-4bd0-8696-f2c0c7487d7b";
            ResourceId = "52cec0e5-b1db-4a0d-bd51-dcffb7c67959"
        };
    }

    $selectedEnvironment = $environments[$Environment]

    $authEndpoint = "https://login.microsoftonline.com/common/oauth2/devicecode?resource=$($selectedEnvironment.ResourceId)&client_id=$($selectedEnvironment.AppId)"
    $tokenEndpoint = "https://login.microsoftonline.com/common/oauth2/token"

    $authResponse = Invoke-RestMethod -Uri $authEndpoint
    try {
        # Windows only for now.
        $authResponse.user_code | clip
    }
    catch {}
    Write-Host $authResponse.message

    $tokenPayload = "resource=$($selectedEnvironment.ResourceId)&client_id=$($selectedEnvironment.AppId)&grant_type=device_code&code=$($authResponse.device_code)"

    $accessToken = ""
    while ($true) {
        try {
            $tokenEndpointResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $tokenPayload
            if ($null -ne $tokenEndpointResponse.access_token) {
                $accessToken = $tokenEndpointResponse.access_token
                break
            }
            Start-Sleep -Seconds $authResponse.interval
        }
        catch {}
    }

    $global:MYCHESS = @{
        "Address" = $environments[$Environment].Address
        "Token"   = $accessToken
    }
}

function Disconnect-MyChess
(
) {
    Remove-Variable MYCHESS -Scope Global -Force
}

function Get-MyChessGame
(
    [Parameter(HelpMessage = "Game state")] 
    [ValidateSet("WaitingForYou", "WaitingForOpponent", "Archive")]
    [string] 
    $GameState = "WaitingForYou"
) {
    $uri = $global:MYCHESS.Address + "/api/games?state=" + $GameState
    $token = ConvertTo-SecureString -String $global:MYCHESS.Token -AsPlainText
    $games = Invoke-RestMethod -Uri $uri -Authentication Bearer -Token $token
    $games
}

function New-MyChessGameMove
(
) {
    throw [System.NotImplementedException]::new()
}

function Get-MyChessFriend
(
) {
    throw [System.NotImplementedException]::new()
}

function New-MyChessGame
(
) {
    throw [System.NotImplementedException]::new()
}
