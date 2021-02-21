// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.10 <0.7.0;

// Implements a Rock/Paper/Scissors game secured by a Commit-Reveal scheme
contract RockPaperScissors {
    
    address payable constant private admin = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    
    uint public bet;
    
    enum Moves {NONE, ROCK, PAPER, SCISSORS}
    
    enum Status {COMMITED, REVEALED}
    
    struct Player {
        address payable addr;
        bytes32 commit;
        Moves move;
        Status status;
    }
    
    Player[2] public players;
    
    uint public winner = 0;
    
    // Contract deployer will be set as Player 1
    constructor(bytes32 p1MoveHash) public payable {
        assert(players[0].addr == address(0) && players[1].addr == address(0)); // There must be no Preexisting players
        require(msg.value > 0, "Player 1 must bet a positive amount");
        bet = msg.value;
        players[0] = Player(msg.sender, p1MoveHash, Moves.NONE, Status.COMMITED); // Add Player 1
    }
    
    // Caller of this function will be set as Player 2
    function player2Commit(bytes32 p2MoveHash) external payable {
        assert(players[0].addr != address(0)); // There must be a preexisting Player 1
        require(players[1].addr == address(0), "There must be no preexisting Player 2");
        require(msg.sender != players[0].addr, "Player 1 can't play against himself.");
        require(msg.value == bet, "Player 2 must match Player 1's bet");
        players[1] = Player(msg.sender, p2MoveHash, Moves.NONE, Status.COMMITED); // Add Player 2
    }
    
    // Reveal
    function reveal(string memory move, string memory salt) external {
        require(hashMatch(move, "rock") || hashMatch(move, "paper") || hashMatch(move, "scissors"), "move must be rock, paper or scissors.");
        require(players[0].addr != address(0) && players[1].addr != address(0), "Can only reveal after 2 Players exist.");
        require(msg.sender == players[0].addr || msg.sender == players[1].addr, "Only valid players can reveal.");
        bytes32 revealHash = keccak256(abi.encodePacked(move, salt));
        
        // If it's player 1
        if (msg.sender == players[0].addr) {validateReveal(revealHash, players[0], move);}
            
        // If it's player 2
        else if (msg.sender == players[1].addr) {validateReveal(revealHash, players[1], move);}
        
        // As soon as both players have revealed, determine winner
        if (players[0].status == Status.REVEALED && players[1].status == Status.REVEALED) {
            getWinner();
        }
    }
    
    function getWinner() internal {
        
        // If it's a tie, or neither player reveals in time (both have their move = Moves.NONE)
        if (players[0].move == players[1].move) {
            admin.transfer(address(this).balance / 100); // admin gets 1% fee
            players[0].addr.transfer(address(this).balance / 2);
            players[1].addr.transfer(address(this).balance);
        }
        
        // If only Player 1 fails to reveal in time, Player 2 wins
        else if (players[0].move == Moves.NONE && players[1].move != Moves.NONE) {payWinner(players[1].addr);}
        
        // If only Player 2 fails to reveal in time, Player 1 wins
        else if (players[0].move != Moves.NONE && players[1].move == Moves.NONE) {payWinner(players[0].addr);}
        
        else if (players[0].move == Moves.ROCK && players[1].move == Moves.PAPER) {payWinner(players[1].addr);}
        else if (players[0].move == Moves.ROCK && players[1].move == Moves.SCISSORS) {payWinner(players[0].addr);}
        
        else if (players[0].move == Moves.PAPER && players[1].move == Moves.ROCK) {payWinner(players[0].addr);}
        else if (players[0].move == Moves.PAPER && players[1].move == Moves.SCISSORS) {payWinner(players[1].addr);}
        
        else if (players[0].move == Moves.SCISSORS && players[1].move == Moves.ROCK) {payWinner(players[1].addr);}
        else if (players[0].move == Moves.SCISSORS && players[1].move == Moves.PAPER) {payWinner(players[0].addr);}
    }
    
    function payWinner(address payable _winner) internal {
        if (_winner == players[0].addr) {winner = 1;}
        else if (_winner == players[1].addr) {winner = 2;}
        admin.transfer(address(this).balance / 100); // admin gets 1% fee
        _winner.transfer(address(this).balance);
    }
    
    function hash(string memory input) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(input));
    }
    
    function hashMatch(string memory input1, string memory input2) internal pure returns(bool) {
        if (hash(input1) == hash(input2)) {return true;}
        else {return false;}
    }
    
    function strToMove(string memory input) internal pure returns(Moves) {
        if (hashMatch(input, "rock")) {return Moves.ROCK;}
        else if (hashMatch(input, "paper")) {return Moves.PAPER;}
        else if (hashMatch(input, "scissors")) {return Moves.SCISSORS;}
    }
    
    function validateReveal(bytes32 inputHash, Player storage player, string memory _move) internal {
        
        // If reveal is valid
        if (inputHash == player.commit) {
            player.move = strToMove(_move);
            player.status = Status.REVEALED;
        }
        
        // If reveal is not valid
        else {revert("Move and Salt do not match your Commit");}
    }
    
}
