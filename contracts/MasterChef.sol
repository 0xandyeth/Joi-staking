// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './libs/Ownable.sol';
import './libs/SafeMath.sol';
import './libs/SafeBEP20.sol';
import './libs/IBEP20.sol';
import './JoiToken.sol';

contract MasterChef is Ownable {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    JoiToken public joi;
    address public devaddr;
    uint256 public JoiPerBlock;
    uint256 public BONUS_MULTIPLIER = 1;

    IBEP20 public lpToken =0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accJoiPerShare;

    mapping (address => UserInfo) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;
    event Deposit(address indexed user, uint256 amount); 
    event Withdraw(address indexed user,uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        JoiToken _joi,
        address _devaddr,
        uint256 _JoiPerBlock,
        uint256 _startBlock

    ) public {
          joi = _joi;
          devaddr = _devaddr;
          JoiPerBlock = _JoiPerBlock;
          startBlock = _startBlock;

          allocPoint = 1000;
          lastRewardBlock=startBlock;
          accJoiPerShare=0;

           totalAllocPoint = 1000;
    }

      function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }
    function updatePool() public {
        if(block.number <= lastRewardBlock){
            return ;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if(lpSupply == 0){
            lastRewardBlock = block.number;
            return;
        }
       uint256 multiplier = getMultiplier(lastRewardBlock,block.number);
       uint256 joiReward = multiplier.mul(JoiPerBlock).mul(allocPoint).div(totalAllocPoint);
       joi.mint(devaddr, joiReward.div(10));
       accJoiPerShare = accJoiPerShare.add(joiReward.mul(1e12).div(lpSupply));
       lastRewardBlock = block.number;

    }
    
    //Stake BNB tokens to MasterChef

    function enterStaking(uint256 _amount) public {
       UserInfo storage user = userInfo[msg.sender];
       updatePool();
       if(user.amount > 0){
           uint256 pending = user.amount.mul(accJoiPerShare).div(1e12).sub(user.rewardDebt);
           if(pending > 0){
               joi.safeTransfer(msg.sender,pending);
           }
       }

       if(_amount > 0){
           lpToken.safeTransferFrom(msg.sender, address(this), _amount);
           user.amount = user.amount.add(_amount);

       }
       user.rewardDebt = user.amount.mul(accJoiPerShare).div(1e12);
       joi.mint(msg.sender, _amount);
       emit Deposit(msg.sender,_amount);
    }

   // Withdraw Joi tokens from STAKING.

   function leaveStaking(uint256 _amount) public {
       UserInfo storage user = userInfo[msg.sender];
       require(user.amount >= _amount,"Withdraw: not good");
       updatePool();
       uint256 pending = user.amount.mul(accJoiPerShare).div(1e12).sub(user.rewardDebt);
       if(pending > 0){
           joi.safeTransfer(msg.sender,pending);
       }

       if(_amount > 0){
           user.amount = user.amount.sub(_amount);
           lpToken.safeTransfer(msg.sender, _amount);
       }
        user.rewardDebt = user.amount.mul(accJoiPerShare).div(1e12);
        joi._burn(msg.sender, _amount);
        emit Withdraw(msg.sender,_amount);

   }


   function emergencyWithdraw() public {
            UserInfo storage user = userInfo[msg.sender];
            lpToken.safeTransfer(msg.sender, user.amount);
             emit EmergencyWithdraw(msg.sender,user.amount);
             user.amount = 0;
             user.rewardDebt = 0;
   }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }






}