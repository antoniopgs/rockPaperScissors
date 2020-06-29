// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.10 <0.7.0;

contract rps {

    address payable constant admin = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    
    enum Moves{NONE, ROCK, PAPER, SCISSORS}
    
    struct Player {
        uint id;
        address payable addr;
        Moves choice;
    }
    
    uint public wager;
    Player[2] players;
    
    function placeBet() external payable {
        require(msg.value > 0, "Player must bet a positive amount");
        
        if (wager == 0) { // If wager = 0 it's because it hasn't bet set yet. 1st Player will set the wager.
            require(players[0].id == 0 && players[1].id == 0, "There must be no Preexisting players");
            
            wager = msg.value; // Set wager.
            players[0] = Player(1, msg.sender, Moves.NONE); // Add 1st Player.
        }
        
        else { // If wager != 0 there is already a wager set by the 1st Player. The 2nd player must match.
            require(players[0].id == 1, "There must be a Preexisting 1st Player");
            require(players[1].id == 0, "There must be no Preexisting 2nd Player");
            require(msg.sender != players[0].addr, "2nd Player must be different than 1st Player");
            require(msg.value == wager, "2nd Player must match 1st Player's bet");
            
            players[1] = Player(2, msg.sender, Moves.NONE); // Add 2nd player.
        }
    }
    
    function viewPot() external view returns(uint) {
        return address(this).balance;
    }
    
    function pickMove(Moves _choice) external {
        require(players[0].id == 1 && players[1].id == 2, "There must exist two authorized players");
        require(msg.sender == players[0].addr && players[0].choice == Moves.NONE ||
                msg.sender == players[1].addr && players[1].choice == Moves.NONE,
                "Only authorized players with no previous moves can pick a move");
        
        require(_choice == Moves.ROCK || _choice == Moves.PAPER || _choice == Moves.SCISSORS, "Player must pick a valid move");
        
        if (msg.sender == players[0].addr) {
            players[0].choice = _choice;
        } else if (msg.sender == players[1].addr) {
            players[1].choice = _choice;
        }
        
        // Both Players must pick their move for the winner to be declared:
        if (players[0].choice != Moves.NONE && players[1].choice != Moves.NONE) {
            getWinner();
        }
    }
    
    function getWinner() internal {
        if (players[0].choice == players[1].choice) { // If it's a tie.
            players[0].addr.transfer(wager);
            players[1].addr.transfer(wager);
        }
        
        else if (players[0].choice == Moves.ROCK && players[1].choice == Moves.PAPER) {payWinner(players[1].addr);}
        else if (players[0].choice == Moves.ROCK && players[1].choice == Moves.SCISSORS) {payWinner(players[0].addr);}
        
        else if (players[0].choice == Moves.PAPER && players[1].choice == Moves.ROCK) {payWinner(players[0].addr);}
        else if (players[0].choice == Moves.PAPER && players[1].choice == Moves.SCISSORS) {payWinner(players[1].addr);}
        
        else if (players[0].choice == Moves.SCISSORS && players[1].choice == Moves.ROCK) {payWinner(players[1].addr);}
        else if (players[0].choice == Moves.SCISSORS && players[1].choice == Moves.PAPER) {payWinner(players[0].addr);}
    }
    
    function payWinner(address payable _winner) internal {
            _winner.transfer( address(this).balance - (address(this).balance / 100) ); // 1% Fee
            admin.transfer(address(this).balance);
    }
}