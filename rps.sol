// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.10 <0.7.0;

contract RockPaperScissors {

    address payable constant admin = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    
    enum Moves{NONE, ROCK, PAPER, SCISSORS}
    
    struct Player {
        address payable addr;
        Moves choice;
    }
    
    Player[2] players;
    
    constructor() public payable {
        require(msg.value > 0, "Player 1 must bet a positive amount");
        assert(
            players[0].addr == 0x0000000000000000000000000000000000000000 && 
            players[1].addr == 0x0000000000000000000000000000000000000000
        ); // There must be no Preexisting players
        players[0] = Player(msg.sender, Moves.NONE); // Add Player 1
    }
    
    function matchBet() external payable {
        require(players[1].addr == 0x0000000000000000000000000000000000000000, "There must be no preexisting Player 2");
        require(msg.sender != players[0].addr, "Player 1 can't match his own bet.");
        require(msg.value == address(this).balance, "Player 2 must match Player 1's bet");
        assert(players[0].addr != 0x0000000000000000000000000000000000000000); // There must be a preexisting Player 1
        players[1] = Player(msg.sender, Moves.NONE); // Add Player 2
    }
    
    function pickMove(Moves _choice) external {
        require(
            players[0].addr != 0x0000000000000000000000000000000000000000 && 
            players[1].addr != 0x0000000000000000000000000000000000000000, 
            "There must exist two authorized players"
            );
        require(msg.sender == players[0].addr && players[0].choice == Moves.NONE ||
                msg.sender == players[1].addr && players[1].choice == Moves.NONE,
                "Only authorized players with no previous moves can pick a move");
        require(_choice == Moves.ROCK || _choice == Moves.PAPER || _choice == Moves.SCISSORS, "Player must pick a valid move");
        
        if (msg.sender == players[0].addr) {
            players[0].choice = _choice;
        } else if (msg.sender == players[1].addr) {
            players[1].choice = _choice;
        }
        
        // If both players have picked a move, declare the winner:
        if (players[0].choice != Moves.NONE && players[1].choice != Moves.NONE) {
            getWinner();
        }
    }
    
    function getWinner() internal {
        if (players[0].choice == players[1].choice) { // If it's a tie.
            players[0].addr.transfer(address(this).balance / 2);
            players[1].addr.transfer(address(this).balance);
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