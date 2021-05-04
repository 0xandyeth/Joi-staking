// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './SafeMath.sol';
import './IERC20.sol';
import './Ownable.sol';
import './Pausable.sol';


contract BNBStaking is Ownable,Pausable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares;
        uint256 lastDepositedTime;
        uint256 lastUserAction;
        uint256 lastUserActionTime;
    }

    IERC20 

}