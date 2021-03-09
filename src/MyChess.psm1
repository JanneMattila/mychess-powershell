$ErrorActionPreference = "Stop"

. $PSScriptRoot\Classes.ps1

$configFile = Join-Path -Path $env:HOME -ChildPath ".mychess" -AdditionalChildPath "mychess.json"

function Connect-MyChess
(
    [Parameter(HelpMessage = "My Chess environment")] 
    [ValidateSet("Development", "Production")]
    [string] 
    $Environment = "Production",

    [Parameter(HelpMessage = "My Chess login tenant")] 
    [ValidateSet("common", "consumers")]
    [string] 
    $Tenant = "consumers"
) {
    Disconnect-MyChess
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
    $tokenEndpoint = "https://login.microsoftonline.com/$Tenant/oauth2/token"

    $authResponse = Invoke-RestMethod -Uri $authEndpoint
    try {
        # Windows only for now.
        $authResponse.user_code | clip
    }
    catch {}
    Write-Host $authResponse.message

    $tokenPayload = "resource=$($selectedEnvironment.ResourceId)&client_id=$($selectedEnvironment.AppId)&grant_type=device_code&code=$($authResponse.device_code)"
    while ($true) {
        try {
            Start-Sleep -Seconds $authResponse.interval
            $tokenEndpointResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $tokenPayload
            if ($null -ne $tokenEndpointResponse.access_token) {
                break
            }
        }
        catch {}
    }
    
    New-Item -Path $configFile -Force | Out-Null
    @{
        "Tenant"       = $Tenant
        "Address"      = $environments[$Environment].Address
        "ResourceId"   = $environments[$Environment].ResourceId
        "AppId"        = $environments[$Environment].AppId
        "RefreshToken" = $tokenEndpointResponse.refresh_token
        "AccessToken"  = $tokenEndpointResponse.access_token
        "Expires"      = $tokenEndpointResponse.expires_on
        "Scope"        = $tokenEndpointResponse.scope
    } | ConvertTo-Json | Set-Content -Path $configFile
}

function Disconnect-MyChess
(
) {
    Remove-Item -Path $configFile -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-MyChessParameter
(
) {
    $parameters = Get-Content -Path $configFile | ConvertFrom-Json
    if ((Get-Date -UnixTimeSeconds $parameters.Value.Expires) -lt (Get-Date -AsUTC)) {
        $refreshEndpoint = "https://login.microsoftonline.com/common/oauth2/token"
        $refreshPayload = "resource=$($parameters.ResourceId)&client_id=$($parameters.AppId)&grant_type=refresh_token&refresh_token=$($parameters.RefreshToken)"
        $refreshResponse = Invoke-RestMethod -Uri $refreshEndpoint -Method POST -Body $refreshPayload
        $refreshResponse
        $parameters.RefreshToken = $refreshResponse.refresh_token
        $parameters.AccessToken = $refreshResponse.access_token
        $parameters.Expires = $refreshResponse.expires_on
        $parameters.Scope = $refreshResponse.scope
        $parameters | ConvertTo-Json | Set-Content -Path $configFile
    }
    $parameters
}

function Get-MyChessGame
(
    [Parameter(HelpMessage = "Game state")] 
    [ValidateSet("WaitingForYou", "WaitingForOpponent", "Archive")]
    [string] 
    $GameState = "WaitingForYou"
) {
    $config = Get-MyChessParameter
    $uri = $config.Address + "/api/games?state=" + $GameState
    $token = ConvertTo-SecureString -String $config.AccessToken -AsPlainText
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
