pragma solidity ^0.5.11;

contract rps {
    
    struct Player {
        uint id;
        address payable addr;
        uint choice; // 1 = Rock, 2 = Paper, 3 = Scissors
    }
    
    Player player1 = Player(1, 0xbDd5804F8eC5D4862C403aF6281caE11FC21f695, 1);
    Player player2 = Player(2, 0x559Dbd861E393B359a55821FAc4b9eB75f42A337, 2);
    
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
        
        if (player1.choice == 1 && player2.choice == 2) {player2.addr.transfer(address(this).balance);}
        if (player1.choice == 1 && player2.choice == 3) {player1.addr.transfer(address(this).balance);}
        
        if (player1.choice == 2 && player2.choice == 1) {player1.addr.transfer(address(this).balance);}
        if (player1.choice == 2 && player2.choice == 3) {player2.addr.transfer(address(this).balance);}
        
        if (player1.choice == 3 && player2.choice == 1) {player2.addr.transfer(address(this).balance);}
        if (player1.choice == 3 && player2.choice == 2) {player1.addr.transfer(address(this).balance);}
        
        else {
            player1.addr.transfer(address(this).balance / 2);
            player2.addr.transfer(address(this).balance / 2);
        }
    }
}