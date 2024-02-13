// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./CommitReveal.sol";

contract RWAPSSF is CommitReveal {
    struct Player {
        bytes32 choice;
        address addr;
        uint depositTime;
    }

    struct Ans {
        uint choice;
    }
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    mapping (uint => Ans) public ans;
    uint public numInput = 0;
    uint public withdrawTime = 15 seconds;
    uint public numReveal = 0;

    function _restartGame() private {
        reward = 0;
        numPlayer = 0;
        numInput = 0;
        numReveal = 0;
    }

    function _checkIfRegis() private view returns (uint) {
        if (msg.sender == player[0].addr) {
            return 0;
        } else if (msg.sender == player[1].addr) {
            return 1;
        } else {
            revert("Sender is not a registered player");
        }
    }

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = bytes32(0);
        player[numPlayer].depositTime = block.timestamp;
        numPlayer++;
    }

    function withdraw() public payable {
        uint idx;
        idx = _checkIfRegis();
        if(numPlayer == 1) {
            address payable account = payable(player[idx].addr);
            account.transfer(reward);
            _restartGame();
        } else if (numPlayer == 2 && numReveal == 0) {
            require((block.timestamp >= player[0].depositTime + withdrawTime) && (block.timestamp >= player[1].depositTime + withdrawTime));
            require(player[(idx+1)%2].choice == bytes32(0) && player[idx].choice != bytes32(0));
            address payable account = payable(player[idx].addr);
            account.transfer(reward);
            _restartGame();
        } else if (numReveal == 1) {
            require((block.timestamp >= player[0].depositTime + withdrawTime) && (block.timestamp >= player[1].depositTime + withdrawTime));
            require(commits[msg.sender].revealed == true);
            address payable account = payable(player[idx].addr);
            account.transfer(reward);
            _restartGame();
        }
    }

    function input(uint choice, uint salt) public  {
        require(numPlayer == 2);
        uint idx;
        idx = _checkIfRegis();
        require(choice >= 0 && choice < 7);
        require(player[idx].choice == bytes32(0));
        player[idx].choice = getSaltedHash(bytes32(choice), bytes32(salt));
        numInput++;
        commit(player[idx].choice);
        player[idx].depositTime = block.timestamp;
    }

    function checkAns(uint answer, uint salt) public {
        require(numInput == 2);
        uint idx = _checkIfRegis();
        revealAnswer(bytes32(answer), bytes32(salt));
        ans[idx].choice = answer;
        numReveal++;
        if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = ans[0].choice;
        uint p1Choice = ans[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 7 == p1Choice || (p0Choice + 2) % 7 == p1Choice || (p0Choice + 3) % 7 == p1Choice) {
            // to pay player[0]
            account0.transfer(reward);
        }
        else if ((p1Choice + 1) % 7 == p0Choice || (p1Choice + 2) % 7 == p0Choice || (p1Choice + 3) % 7 == p0Choice) {
            // to pay player[1]
            account1.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        _restartGame();
    }
}
