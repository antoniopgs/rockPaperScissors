// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.10 <0.7.0;

// Implements a Rock/Paper/Scissors game secured by a Commit-Reveal scheme
contract RockPaperScissors {
    
    address payable constant private admin = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    
    uint private bet;
    
    uint private commitDeadline;
    
    uint private revealPhaseSeconds;
    
    uint private revealDeadline;
    
    enum Moves {NONE, ROCK, PAPER, SCISSORS}
    
    enum Status {NONE, COMMITED, REVEALED}
    
    struct Player {
        address payable addr;
        bytes32 commit;
        Moves move;
        Status status;
    }
    
    Player[2] private players;
    
    /*
        Contract deployer will be set as Player 1
        Move format examples: rock123, paperabc, scissorsxyz999
        Don't forget to prepend your hash with "0x" if needed
    */
    constructor(uint commitPhaseSeconds, uint _revealPhaseSeconds, bytes32 p1MoveHash) public payable {
        require(commitPhaseSeconds >= 60 && commitPhaseSeconds <= 300, "Commit Phase must last between 60 and 300 seconds.");
        require(_revealPhaseSeconds >= 60 && _revealPhaseSeconds <= 300, "Reveal Phase must last between 60 and 300 seconds.");
        
        assert(players[0].addr == address(0) && players[1].addr == address(0)); // There must be no Preexisting players
        assert(players[0].status != Status.COMMITED && players[0].status != Status.REVEALED); // Player 1 must have no status
        require(msg.value > 0, "Player 1 must bet a positive amount");
        bet = msg.value; // Set bet Player 2 will need to match
        players[0] = Player(msg.sender, p1MoveHash, Moves.NONE, Status.COMMITED); // Add Player 1
        revealPhaseSeconds = _revealPhaseSeconds; // Set Reveal Phase Duration - will be used in player2Commit()
        commitDeadline = now + commitPhaseSeconds; // Set Commit Deadline
    }
    
    /*
        Caller of this function will be set as Player 2
        Move format examples: rock123, paperabc, scissorsxyz999
        Don't forget to prepend your hash with "0x" if needed
    */
    function player2Commit(bytes32 p2MoveHash) external payable {
        require(now < commitDeadline, "Commit Phase is over");
        assert(players[0].addr != address(0)); // There must be a preexisting Player 1
        assert(players[0].status == Status.COMMITED); // Player 1 must have commited.
        require(msg.sender != players[0].addr, "Player 1 can't play against himself.");
        require(players[1].addr == address(0), "There must be no preexisting Player 2");
        require(msg.value == bet, "Player 2 must match Player 1's bet");
        require(players[1].status != Status.COMMITED && players[1].status != Status.REVEALED, "You already commited");
        players[1] = Player(msg.sender, p2MoveHash, Moves.NONE, Status.COMMITED); // Add Player 2
        
        // As soon as Player 2 commits, start reveal Phase
        revealDeadline = now + revealPhaseSeconds;
    }
    
    // Reveal
    function reveal(string memory move, string memory salt) external {
        
        // If the Reveal Phase is not over
        if (now < revealDeadline) {
            require(
                hashMatch(move, "rock") || 
                hashMatch(move, "paper") || 
                hashMatch(move, "scissors"), 
                "move must be rock, paper or scissors."
            );
            require(msg.sender == players[0].addr || msg.sender == players[1].addr, "Only valid players can reveal.");
            bytes32 revealHash = keccak256(abi.encodePacked(move, salt));
            
            // If it's Player 1
            if (msg.sender == players[0].addr) {
                
                // Player 2 must revealed, or at least committed
                require(players[1].status == Status.REVEALED || players[1].status == Status.COMMITED);
                
                // Validate Player 1 reveal
                validateReveal(revealHash, players[0], move);
            }
                
            // If it's Player 2
            else if (msg.sender == players[1].addr) {
                
                // Player 1 must revealed, or at least committed
                require(players[1].status == Status.REVEALED || players[1].status == Status.COMMITED);
                
                // Validate Player 2 reveal
                validateReveal(revealHash, players[1], move);
            }
            
            // As soon as both players have revealed, determine winner
            if (players[0].status == Status.REVEALED && players[1].status == Status.REVEALED) {
                getWinner();
            }
            
        // If the Reveal Phase is over, either player can call this function to determine winner, and get their money
        } else {
            
            // This function is prepared for Players who don't reveal
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
        admin.transfer(address(this).balance / 100); // admin gets 1% fee
        _winner.transfer(address(this).balance);
    }
    
    function validateReveal(bytes32 inputHash, Player storage player, string memory _move) internal {
        
        // To Reveal, player status must be COMMITED
        require(player.status == Status.COMMITED, "You already revealed");
        
        // If reveal is valid
        if (inputHash == player.commit) {
            player.move = strToMove(_move);
            player.status = Status.REVEALED;
        }
        
        // If reveal is not valid
        else {revert("Move and Salt do not match your Commit");}
    }
    
    // If no Player 2 commits until commit phase is over, Player 1 can get refund
    function refundPlayer1() external {
        require(msg.sender == players[0].addr, "Only Player 1 can get a refund");
        require (now > commitDeadline, "You cannot get a refund until the commit phase is over");
        require(players[1].addr == address(0), "No refunds if Player 2 exists. Wait until end of Reveal Phase");
        assert(address(this).balance == bet); // Contract balance should be equal to bet.
        players[0].addr.transfer(bet);
    }
    
    function hash(string memory input) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(input));
    }
    
    function hashMatch(string memory input1, string memory input2) internal pure returns(bool) {
        if (hash(input1) == hash(input2)) {return true;}
        else {return false;}
    }
    
    // Convert move strings into "Moves" Enum values
    function strToMove(string memory input) internal pure returns(Moves) {
        if (hashMatch(input, "rock")) {return Moves.ROCK;}
        else if (hashMatch(input, "paper")) {return Moves.PAPER;}
        else if (hashMatch(input, "scissors")) {return Moves.SCISSORS;}
    }
    
    function viewBet() external view returns(uint) {
        return bet;
    }
    
    function viewCommitSecondsLeft() external view returns(uint) {
        if (now < commitDeadline) {return commitDeadline - now;}
        else {return 0;}
    }
    
    function viewRevealSecondsLeft() external view returns(uint) {
        if (now < revealDeadline) {return revealDeadline - now;}
        else {return 0;}
    }
}
