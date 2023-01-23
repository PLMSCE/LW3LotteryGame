//SPDX-Licence-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {

    uint256 public fee;
    bytes32 public keyHash;
    address[] public players;
    uint8 public maxPlayers;
    bool public gameStarted;
    uint256 entryFee;
    uint256 gameId;

    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryfee);
    event PlayerJoined(uint256 gameId, address player);
    event gameEnded(uint256 gameId, address winner, bytes32 requestId);

    constructor(address vrfCoordinator, address linkToken, bytes32 vrfKeyHash, uint vrfFee)
    VRFConsumerBase(vrfCoordinator, linkToken){
        keyHash = vrfKeyHash;
        fee = vrfFee;
        gameStarted = false;
    }

    function startGame(uint8 _maxPlayers, uint256 _entryFee)public onlyOwner{
        require(!gameStarted, "Game is currently running");
        delete players;
        maxPlayers = _maxPlayers;
        gameStarted = true;
        entryFee = _entryFee;
        gameId += 1;
        emit GameStarted(gameId, maxPlayers, entryFee);
    }
    function joinGame() public payable{
        require(gameStarted, "game has not started yet.");
        require(msg.value == entryFee, "value does not equal the entry fee.");
        require(players.length < maxPlayers, "game is full.");
        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);
        if(players.length == maxPlayers){
            getRandomWinner();
        }
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override{
        uint256 winnerIndex = randomness % players.length;
        address winner = players[winnerIndex];
        (bool sent,) = winner.call{value:address(this).balance}("");
        emit gameEnded(gameId, winner, requestId);
        gameStarted = false;
    }
    function getRandomWinner() private returns (bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "Insufficient Link Balance.");
        return requestRandomness(keyHash, fee);
    }
    receive() external payable {}

    fallback() external payable{}


}