. $PSScriptRoot\Classes.ps1

function Connect-MyChess
(
    [Parameter(HelpMessage = "My Chess environment")] 
    [ValidateSet("Development", "Production")]
    [string] $Environment = "Production"    
) {
    $environments = @{ 
        "Development" = @{
            Address    = "https://mychess-dev.jannemattila.com";
            AppId      = "f4617c7d-a6c2-444a-b7c0-a9942dd88b3c";
            ResourceId = "9ea259c1-4a8c-489a-86d5-54fa90dc3fd3"
        };
        "Production"  = @{
            Address    = "https://mychess.jannemattila.com";
            AppId      = "6a824c79-d2d8-4bd0-8696-f2c0c7487d7b";
            ResourceId = "52cec0e5-b1db-4a0d-bd51-dcffb7c67959"
        };
    }
}

function Disconnect-MyChess
(
) {
    throw [System.NotImplementedException]::new()
}

function Get-MyChessGame
(
) {
    throw [System.NotImplementedException]::new()
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
