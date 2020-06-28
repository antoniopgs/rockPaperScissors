pragma solidity ^0.5.11;

contract rps {
    
    enum Moves{NONE, ROCK, PAPER, SCISSORS}
    
    struct Player {
        uint id;
        address payable addr;
        Moves choice;
    }
    
    uint wager;
    Player[2] players;
    bool gameIsOver;
    Player winner;
    
    function placeBet() external payable {
        require(msg.value > 0, "Players must bet a positive amount");
        
        if (wager == 0) { // If wager = 0 it's because it hasn't bet set yet. 1st Player will set the wager.
            require(players[0].id == 0 && players[1].id == 0, "There must be no Preexisting players");
            
            wager = msg.value; // Set wager.
            players[0] = Player(1, msg.sender, Moves.NONE); // Add 1st Player.
        }
        
        else { // If wager != 0 there is already a wager set by the 1st Player. The 2nd player must match.
            require(msg.value == wager, "Second Player must match First Player's bet");
            require(msg.sender != players[0].addr, "Second Player must be different than First Player");
            require(players[0].id != 0, "There must be a Preexisting 1st Player");
            require(players[1].id == 0, "There must be no Preexisting 2nd Player");
            
            players[1] = Player(2, msg.sender, Moves.NONE); // Add 2nd player.
        }
    }
    
    function viewPot() external view returns(uint) {
        return address(this).balance;
    }
    
    function play(Moves _choice) external {
        require(
        msg.sender == players[0].addr && players[0].choice == Moves.NONE
        ||
        msg.sender == players[1].addr && players[1].choice == Moves.NONE,
        "Only authorized players with no previous moves can choose a move"
        );
        
        require(_choice == Moves.ROCK || _choice == Moves.PAPER || _choice == Moves.SCISSORS, "Player must choose a valid move");
        
        if (msg.sender == players[0].addr) {
            players[0].choice = _choice;
        }
        else if (msg.sender == players[1].addr) {
            players[1].choice = _choice;
        }
        else {
            revert("Sender must be an authorized player");
        }
        
        // If there is a Tie or Invalid Inputs, game.winner remains = 0
        
        if (players[0].choice == Moves.ROCK && players[1].choice == Moves.PAPER) {winner = players[1];}
        if (players[0].choice == Moves.ROCK && players[1].choice == Moves.SCISSORS) {winner = players[0];}
        
        if (players[0].choice == Moves.PAPER && players[1].choice == Moves.ROCK) {winner = players[0];}
        if (players[0].choice == Moves.PAPER && players[1].choice == Moves.SCISSORS) {winner = players[1];}
        
        if (players[0].choice == Moves.SCISSORS && players[1].choice == Moves.ROCK) {winner = players[1];}
        if (players[0].choice == Moves.SCISSORS && players[1].choice == Moves.PAPER) {winner = players[0];}
        
        gameIsOver = true;
        
        sendWei();
    }
    
    function sendWei() internal {
        require(gameIsOver == true);
        if (winner.id == 0) {
            players[0].addr.transfer(address(this).balance / 2);
            players[1].addr.transfer(address(this).balance / 2);
        }
        else if (winner.id == players[0].id) {
            players[0].addr.transfer(address(this).balance);
        }
        else if (winner.id == players[1].id) {
            players[1].addr.transfer(address(this).balance);
        }
    }
}