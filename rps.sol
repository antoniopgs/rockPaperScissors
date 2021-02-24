// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

// Implements a Rock/Paper/Scissors game secured by a Commit-Reveal scheme
contract RockPaperScissors {
    
    address payable constant private admin = payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    
    uint public bet;
    
    uint private commitDeadline;
    
    uint private revealPhaseSeconds;
    
    uint private revealDeadline;
    
    enum Moves {NONE, ROCK, PAPER, SCISSORS}
    
    struct Player {
        address payable addr;
        bytes32 commit;
        Moves move;
    }
    
    Player[2] private players;
    
    //Contract deployer will be set as Player 1
    constructor(uint commitPhaseSeconds, uint _revealPhaseSeconds) {
        
        // Validate Phase Durations
        require(commitPhaseSeconds >= 60 && commitPhaseSeconds <= 300, "Commit Phase must last between 60 and 300 seconds.");
        require(_revealPhaseSeconds >= 60 && _revealPhaseSeconds <= 300, "Reveal Phase must last between 60 and 300 seconds.");
        
        // Set Player 1 as Contract Deployer
        players[0].addr = payable(msg.sender);
        
        // Set Reveal Phase Duration - will be used in commit()
        revealPhaseSeconds = _revealPhaseSeconds;
        
        // Set Commit Deadline
        commitDeadline = block.timestamp + commitPhaseSeconds;
    }
    
    /*
        Move format:
        - Description: first character must be int (1 for rock, 2 for paper, 3 for scissors). Add random stuff after
        - Examples: "1aaa" (rock), "2999" (paper), 3a1b2c3 (scissors)
        Don't forget to prepend your "moveHash" with "0x" if needed
    */
    function commit(bytes32 moveHash) external payable {
        
        // Validate Commit Phase isn't over
        require(block.timestamp < commitDeadline, "Commit Phase is over");
        
        // If no bet was placed
        if (bet == 0) {
            require(msg.value > 0, "Player must set a bet with a positive amount");
            bet = msg.value;
            
        // If a bet was already placed
        } else {
            require(msg.value == bet, "Player must match bet.");
        }
        
        // If it's the Contract Deployer (Player 1)
        if (msg.sender == players[0].addr) {
            require(players[0].commit == 0, "You already commited");
            assert(players[0].move == Moves.NONE); // If Player 1 hasn't yet commited, he should have no move.
            
            // Add Player 1's commit (his address was already set in constructor and move is already NONE by default)
            players[0].commit = moveHash;
        
        // If it's not the Contract Deployer (Player 2)
        } else {
            require(players[1].addr == address(0), "Player 2 already exists.");
            assert(players[1].commit == 0 && players[1].move == Moves.NONE); // If P2 doesn't exist, he should have no commit or move
            
            // Add Player 2
            players[1] = Player(payable(msg.sender), moveHash, Moves.NONE);
        }
        
        // As soon as both players have committed, start Reveal Phase
        if (players[0].commit != 0 && players[1].commit != 0) {
            
            // Set Reveal Deadline
            revealDeadline = block.timestamp + revealPhaseSeconds;
        }
    }
    
    // Reveal
    function reveal(Moves move, string calldata salt) external {
        
        // Validate both players have committed
        require(players[0].commit != 0 && players[1].commit != 0, "Can only reveal after both players commit");
        
        // Ensure it's a valid player
        require(msg.sender == players[0].addr || msg.sender == players[1].addr, "Only valid players can reveal.");
        
        // If the Reveal Phase is not over
        if (block.timestamp < revealDeadline) {
            
            // Ensure input hashes to a valid move
            require(move == Moves.ROCK || move == Moves.PAPER || move == Moves.SCISSORS, "move must be rock, paper or scissors.");
            
            // Set Reveal Hash
            bytes32 revealHash = keccak256(abi.encodePacked(enumToStr(move), salt));
            
            // If it's Player 1
            if (msg.sender == players[0].addr) {
                
                // Validate Player 1 reveal
                validateReveal(revealHash, players[0], move);
            }
                
            // If it's Player 2
            else if (msg.sender == players[1].addr) {
                
                // Validate Player 2 reveal
                validateReveal(revealHash, players[1], move);
            }
            
            // As soon as both players have revealed (have a move), determine winner
            if (players[0].move != Moves.NONE && players[1].move != Moves.NONE) {
                getWinner();
            }
            
        // If the Reveal Phase is over...
        } else {
            
            /*
                ... and if someone didn't reveal in time, either player can reveal() with dummy data to proceed with the game
                getWinner() is prepared in case one or both players don't reveal
            */
            getWinner();
        }
        
    }
    
    function getWinner() internal {
        
        // If it's a tie, or neither player reveals in time (both have their move = Moves.NONE)
        if (players[0].move == players[1].move) {
            admin.transfer((bet * 2) / 100); // admin gets 1% fee
            players[0].addr.transfer((bet * 99) / 100);
            players[1].addr.transfer((bet * 99) / 100);
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
        admin.transfer((bet * 2) / 100); // admin gets 1% fee
        _winner.transfer(((bet * 2) * 99) / 100);
    }
    
    // Transform enums to strings, to facilitate revealHash calculation
    function enumToStr(Moves move) internal pure returns(string memory) {
        if (move == Moves.ROCK) {return "1";}
        else if (move == Moves.PAPER) {return "2";}
        else if (move == Moves.SCISSORS) {return "3";}
        else revert("Invalid move");
    }
    
    function validateReveal(bytes32 inputHash, Player storage player, Moves move) internal {
        
        // To Reveal, player must have not revealed before (have no move)
        require(player.move == Moves.NONE, "You already revealed");
    
        // If reveal is valid
        if (inputHash == player.commit) {
            player.move = move;
        }
        
        // If reveal is not valid
        else {revert("Move and Salt do not match your Commit");}
    }
    
    // If only one Player commits, he can get a refund when commit phase is over
    function getRefund() external {
        require(msg.sender == players[0].addr || msg.sender == players[1].addr, "Only valid players can get a refund");
        require (block.timestamp > commitDeadline, "You cannot get a refund until the commit phase is over");
        
        // If Player 1 wants a refund
        if (msg.sender == players[0].addr) {
            
            // Ensure Player 1 has committed
            require(players[0].commit != 0, "You have not committed. Refund unauthorized.");
            
            // Ensure Player 2 has not committed
            require(players[1].commit == 0, "Player 2 has committed. Refund unauthorized.");
        
        // If Player 2 wants a refund
        } else if (msg.sender == players[1].addr) {
            
            // Ensure Player 2 has committed
            require(players[1].commit != 0, "You have not committed. Refund unauthorized.");
            
            // Ensure Player 1 has not committed
            require(players[0].commit == 0, "Player 1 has committed. Refund unauthorized.");
        }
        
        // Refund Player
        payable(msg.sender).transfer(bet);
    }
    
    // Anyone can view time left until Commit Deadline
    function viewCommitSecondsLeft() external view returns(uint) {
        
        // Return seconds left until COmmit Deadline
        if (block.timestamp < commitDeadline) {return commitDeadline - block.timestamp;}
        else {return 0;}
    }
    
    // Only valid players should be able to see time left until Reveal Deadline
    function viewRevealSecondsLeft() external view returns(uint) {
        
        // Validate viewer is Player 1 or Player 2
        require(msg.sender == players[0].addr || msg.sender == players[1].addr, "Unauthorized");
        
        // Return seconds left until Reveal Deadline
        if (block.timestamp < revealDeadline) {return revealDeadline - block.timestamp;}
        else {return 0;}
    }
}
