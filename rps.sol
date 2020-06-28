pragma solidity ^0.5.11;

contract rps {
    
    enum Moves{ROCK, PAPER, SCISSORS}
    
    struct Player {
        uint id;
        address payable addr;
        Moves choice;
    }
    
    Player player1 = Player(1, 0xbDd5804F8eC5D4862C403aF6281caE11FC21f695, Moves.ROCK);
    Player player2 = Player(2, 0x559Dbd861E393B359a55821FAc4b9eB75f42A337, Moves.SCISSORS);
    
    function placeBet() external payable {}
    
    function viewBet() external view returns(uint) {
        return address(this).balance;
    }
    
    function play() external payable returns(string memory) {
        
        // If Tie:
        if (player1.choice == player2.choice) {
            player1.addr.transfer(address(this).balance / 2);
            player2.addr.transfer(address(this).balance / 2);
        }
        
        if (player1.choice == Moves.ROCK && player2.choice == Moves.PAPER) {player2.addr.transfer(address(this).balance);}
        if (player1.choice == Moves.ROCK && player2.choice == Moves.SCISSORS) {player1.addr.transfer(address(this).balance);}
        
        if (player1.choice == Moves.PAPER && player2.choice == Moves.ROCK) {player1.addr.transfer(address(this).balance);}
        if (player1.choice == Moves.PAPER && player2.choice == Moves.SCISSORS) {player2.addr.transfer(address(this).balance);}
        
        if (player1.choice == Moves.SCISSORS && player2.choice == Moves.ROCK) {player2.addr.transfer(address(this).balance);}
        if (player1.choice == Moves.SCISSORS && player2.choice == Moves.PAPER) {player1.addr.transfer(address(this).balance);}
        
        else {
            player1.addr.transfer(address(this).balance / 2);
            player2.addr.transfer(address(this).balance / 2);
        }
    }
}