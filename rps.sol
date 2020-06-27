pragma solidity ^0.5.11;

contract rps {
    
    uint256 player1;
    uint256 player2;
    
    function set1(uint256 _player1) external returns(uint256) {
        player1 = _player1;
        return player1;
    }
    
    function set2(uint _player2) external returns(uint256) {
        player2 = _player2;
        return player2;
    }
    
    function play() external view returns(string memory) {
        if (player1 == player2) {
            return "Tie";
        }
        
        if (player1 == 1) {
            if (player2 == 2) {
                return "Player 2 wins";
            }
            if (player2 == 3) {
                return "Player 1 wins";
            }
        }
        
        if (player1 == 2) {
            if (player2 == 3) {
                return "Player 2 wins";
            }
            if (player2 == 1) {
                return "Player 1 wins";
            }
        }
        
        if (player1 == 3) {
            if (player2 == 1) {
                return "Player 2 wins";
                
            }
            if (player2 == 2) {
                return "Player 1 wins";
                
            }
        }
        
        else {
            return "Invalid input";
        }
    }
}
