pragma solidity ^0.5.11;

contract rps {
    
    enum Moves{ROCK, PAPER, SCISSORS}
    
    struct Player {
        uint id;
        address payable addr;
        Moves choice;
    }
    
    struct Game {
        uint wager;
        Player player1;
        Player player2;
        bool isOver;
        uint winnerId;
    }
    
    Game game;
    
    function placeBet(uint _wager, address payable _address1, address payable _address2) external payable {
        if (_address2.balance >= msg.value) { // Check if Player 2 has enough money to place the same bet as player 1.
            game = Game(
            _wager,
            Player(1, _address1, Moves.ROCK),
            Player(2, _address2, Moves.SCISSORS),
            false, // Game just started so game.isOver = false
            0 // Winner hasn't been determined yet so game.winner = 0
            );
        }
    }
    
    function viewPot() external view returns(uint) {
        return address(this).balance;
    }
    
    function play() external {
        // If there is a Tie or Invalid Inputs, game.winner remains = 0
        
        if (game.player1.choice == Moves.ROCK && game.player2.choice == Moves.PAPER) {game.winnerId = game.player2.id;}
        if (game.player1.choice == Moves.ROCK && game.player2.choice == Moves.SCISSORS) {game.winnerId = game.player1.id;}
        
        if (game.player1.choice == Moves.PAPER && game.player2.choice == Moves.ROCK) {game.winnerId = game.player1.id;}
        if (game.player1.choice == Moves.PAPER && game.player2.choice == Moves.SCISSORS) {game.winnerId = game.player2.id;}
        
        if (game.player1.choice == Moves.SCISSORS && game.player2.choice == Moves.ROCK) {game.winnerId = game.player2.id;}
        if (game.player1.choice == Moves.SCISSORS && game.player2.choice == Moves.PAPER) {game.winnerId = game.player1.id;}
        
        game.isOver = true;
        
        sendWei();
    }
    
    function sendWei() internal {
        if (game.isOver == true) {
            if (game.winnerId == 0) {
                game.player1.addr.transfer(address(this).balance / 2);
                game.player2.addr.transfer(address(this).balance / 2);
            } else if (game.winnerId == 1) {
                game.player1.addr.transfer(address(this).balance);
            } else if (game.winnerId == 2) {
                game.player2.addr.transfer(address(this).balance);
            }
        }
    }
}