// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPS {
    struct Player {
        uint choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
        address addr;
        uint depositTime;
    }
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numInput = 0;
    uint public withdrawTime = 10 seconds;

    function checkIfRegis() private view returns (uint) {
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
        player[numPlayer].choice = 3;
        player[numPlayer].depositTime = block.timestamp;
        numPlayer++;
    }

    function withdraw() public payable {
        require(numPlayer == 1);
        uint idx;
        idx = checkIfRegis();
        require(block.timestamp >= player[idx].depositTime + withdrawTime);
        address payable account0 = payable(player[0].addr);
        account0.transfer(reward);
        reward -= 1 ether;
        numPlayer--;
    }

    function input(uint choice) public  {
        require(numPlayer == 2);
        uint idx;
        idx = checkIfRegis();
        require(choice == 0 || choice == 1 || choice == 2);
        player[idx].choice = choice;
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 3 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 3 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
}
