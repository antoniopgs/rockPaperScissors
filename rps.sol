pragma solidity ^0.5.11;

contract rps {
    
    function play(uint player1, uint player2) external pure returns(string memory) {
        
        if (player1 == player2) {return "Tie";}
        
        if (player1 == 1 && player2 == 2) {return "Player 2 wins";}
        if (player1 == 1 && player2 == 3) {return "Player 1 wins";}
        
        if (player1 == 2 && player2 == 1) {return "Player 1 wins";}
        if (player1 == 2 && player2 == 3) {return "Player 2 wins";}
        
        if (player1 == 3 && player2 == 1) {return "Player 2 wins";}
        if (player1 == 3 && player2 == 2) {return "Player 1 wins";}
        
        else {return "Invalid input";}
        
    }
}