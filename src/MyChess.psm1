$ErrorActionPreference = "Stop"

. $PSScriptRoot\Classes.ps1

$configFile = Join-Path -Path $env:HOME -ChildPath ".mychess" -AdditionalChildPath "mychess.json"
Add-Type -Path $PSScriptRoot\MyChess.dll

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

    $authPayload = "scope=offline_access $($selectedEnvironment.ResourceId)/.default&client_id=$($selectedEnvironment.AppId)"

    $authEndpoint = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/devicecode"
    $tokenEndpoint = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"

    $authResponse = Invoke-RestMethod -Uri $authEndpoint -Method Post -Body $authPayload
    try {
        # Windows only for now.
        $authResponse.user_code | clip
    }
    catch {}
    Write-Host $authResponse.message

    $tokenTime = [int64](Get-Date -AsUTC -UFormat %s)
    $tokenPayload = "client_id=$($selectedEnvironment.AppId)&grant_type=urn:ietf:params:oauth:grant-type:device_code&device_code=$($authResponse.device_code)"
    while ($true) {
        try {
            Start-Sleep -Seconds $authResponse.interval
            $tokenEndpointResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $tokenPayload
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
        "Expires"      = $tokenTime + $tokenEndpointResponse.expires_in
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
    if ((Get-Date -UnixTimeSeconds $parameters.Expires) -lt (Get-Date -AsUTC)) {
        $tokenTime = [int64](Get-Date -AsUTC -UFormat %s)
        $refreshEndpoint = "https://login.microsoftonline.com/$($parameters.Tenant)/oauth2/v2.0/token"
        $refreshPayload = "scope=offline_access $($parameters.ResourceId)/.default&client_id=$($parameters.AppId)&grant_type=refresh_token&refresh_token=$($parameters.RefreshToken)"
        $refreshResponse = Invoke-RestMethod -Uri $refreshEndpoint -Method Post -Body $refreshPayload
        $parameters.RefreshToken = $refreshResponse.refresh_token
        $parameters.AccessToken = $refreshResponse.access_token
        $parameters.Expires = $tokenTime + $refreshResponse.expires_in
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
    $games = [MyChess.Interfaces.MyChessGame[]](Invoke-RestMethod -Uri $uri -Authentication Bearer -Token $token)
    $games
}

function Get-MyChessBoard
(
    [Parameter(HelpMessage = "Game", Mandatory)] 
    [MyChess.Interfaces.MyChessGame] 
    $Game
) {
    $board = [MyChess.Chessboard]::new()
    $board.Load($Game)
    $board
}

function New-MyChessGameMove
(
) {
    throw [System.NotImplementedException]::new()
}

function Get-MyChessFriend
(
) {
    $config = Get-MyChessParameter
    $uri = $config.Address + "/api/users/me/friends"
    $token = ConvertTo-SecureString -String $config.AccessToken -AsPlainText
    $friends = [MyChess.Interfaces.User[]](Invoke-RestMethod -Uri $uri -Authentication Bearer -Token $token)
    $friends
}

function New-MyChessGame
(
) {
    throw [System.NotImplementedException]::new()
}
