class User {
    [string] $ID
    [string] $Name
}

class MyChessPlayers {
    [User] $White
    [User] $Black
}

class MyChessGameMove {
    [string] $Move
    [string] $Comment
    [string] $Capture
    [string] $Start
    [string] $End
    [string] $Promotion
}

class MoveSubmit {
    [string] $ID
    [MyChessGameMove] $Move
}

class MyChessGame {
    [string] $ID
    [string] $Name
    [string] $State
    [string] $StateText
    [datetime] $Updated
    [MyChessPlayers] $Players
    [array] $Moves
}
