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
    
    function placeBet() external payable {
        game = Game(
            msg.value,
            Player(1, 0x583031D1113aD414F02576BD6afaBfb302140225, Moves.ROCK),
            Player(2, 0xdD870fA1b7C4700F2BD7f44238821C26f7392148, Moves.SCISSORS),
            false, // Game just started so game.isOver = false
            0 // Winner hasn't been determined yet so game.winner = 0
            );
    }

    function viewBet() external view returns(uint) {
        return game.wager;
    }
    
    function play() external payable returns(string memory) {
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