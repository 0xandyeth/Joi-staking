//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath{
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }
    
     function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }
    
      function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
      function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }
    
     function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

}


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// contract JoiStaking {
//     using SafeMath for uint256;
//     using EnumerableSet for EnumerableSet.AddressSet;
    
//     event RewardsTransferred(address holder, uint256 amount);
    
//     IBEP20 public rewardToken;
    
//     address public treasury;
    
//     address public admin;
    
//     //WBNB
//     address public immutable WBNB;
    
//     uint256 public constant MAX_PERFORMANCE_FEE = 500; // 5%
//     uint256 public constant MAX_CALL_FEE = 100; // 1%
//     uint256 public constant MAX_WITHDRAW_FEE = 100; // 1%
    
//     // reward rate 120.00% per year
    
//     uint256 public constant rewardRate = 12000;
//     uint256 public constant rewardInterval = 365 days;
    
//     uint256 public performanceFee = 500; // 5%
//     uint256 public callFee = 25; // 0.25%
//     uint256 public withdrawFee = 10; // 0.1%
    
    
//     mapping(address => uint256) public depositedTokens;
    
    
//     constructor(IBEP20 _rewardToken,address _wbnb) public {
//         rewardToken = _rewardToken;
//         WBNB = _wbnb;
//     }
    
//     modifier onlyAdmin(){
//         require(msg.sender == admin,"admin: wut?");
//         _;
//     }
    
    
//     receive() external payable {
//         assert(msg.sender == WBNB); // only accept BNB via fallback from the WBNB contract 
//     }
    
//     function deposit() public payable{
//         require(msg.value > 0,"stake amount is not zero.");
        
//         IWBNB(WBNB).deposit{value:msg.value}();
//         assert(IWBNB(WBNB).transfer(address(this),msg.value));
        
//         depositedTokens[msg.sender] = depositedTokens[msg.sender].add(msg.value);
        
//     }
    
    

    
    
    
    
// }


contract JoiStaking is Ownable{
    
    using SafeMath for uint256;
    
    
    //Info of each user.
    
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    
    //Info of each pool
    
    struct PoolInfo {
        IBEP20 token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accJoiPerShare;
    }
    
    // Reward token
    IBEP20 public rewardToken;
    
    //adminAddress
    
    address public adminAddress;
    
    
    address public immutable WBNB;
    
    // JOI tokens created per block
    
    uint256 public rewardPerBlock;
    
    //Info of each Pool
    
    PoolInfo[] public poolInfo;
    
    //Info of each user that stakes tokens
    mapping(address => UserInfo) public userInfo;
    
    // limit 10 BNB here
    
    uint256 public limitAmount =10000000000000000000; 
    
    
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    
    // The block number when JOI mining starts.
    uint256 public startBlock;
    
    // The block number when JOI mining ends.
    uint256 public bonusEndBlock;
    
    event Deposit(address indexed user,uint256 amount);
    event Withdraw(address indexed user,uint256 amount);
    event EmergencyWithdraw(address indexed user,uint256 amount);
    
    
    constructor(
        IBEP20 _token,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusBlock,
        address _adminAddress,
        address _wbnb
        ) public {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        WBNB = _wbnb;
        startBlock = _startBlock;
        bonusEndBlock = _bonusBlock;
        adminAddress = _adminAddress;
        
        // staking pool
        poolInfo.push(PoolInfo({
            token:_token,
            allocPoint:1000,
            lastRewardBlock:startBlock,
            accJoiPerShare:0
        }));
        
        totalAllocPoint = 1000;
        
        
    }
    
    
    modifier onlyAdmin() {
        require(msg.sender == adminAddress,"admin:wut?");
        _;
    }
    
    receive() external payable {
        assert(msg.sender == WBNB); 
    }
    
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }
    
    
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from ,uint256 _to) public view returns(uint256){
        
         if(_to <= bonusEndBlock){
             return _to.sub(_from);
         } else if(_from >= bonusEndBlock){
             return 0;
         } else {
             return bonusEndBlock.sub(_from);
         }
    }
    
    // View function to see pending Reward on frontend
    
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accJoiPerShare = pool.accJoiPerShare;
        uint256 balance = pool.token.balanceOf(address(this));
        if(block.number > pool.lastRewardBlock && balance != 0){
            uint256 multiplier = getMultiplier(pool.lastRewardBlock,block.number);
            uint256 joiReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accJoiPerShare = accJoiPerShare.add(joiReward.mul(1e12).div(balance));
        }
        return user.amount.mul(accJoiPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if(block.number <= pool.lastRewardBlock){
            return;
        }
        
        uint256 balance = pool.token.balanceOf(address(this));
        
        if(balance == 0){
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 multiplier = getMultiplier(pool.lastRewardBlock,block.number);
        uint256 joiReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accJoiPerShare = pool.accJoiPerShare.add(joiReward.mul(1e12).div(balance));
        pool.lastRewardBlock  = block.number;
        
    }
    
    
    // Stake tokens
    function deposit() public payable{
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        
        require(user.amount.add(msg.value) <= limitAmount,'exceed the top');
        
        updatePool(0);
        
        if(user.amount > 0){
            uint256 pending = user.amount.mul(pool.accJoiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0){
                rewardToken.transfer(address(msg.sender),pending);
            }
        }
        if(msg.value > 0){
            IWBNB(WBNB).deposit{value:msg.value}();
            assert(IWBNB(WBNB).transfer(address(this),msg.value));
            user.amount = user.amount.add(msg.value);
        }
        
        user.rewardDebt = user.amount.mul(pool.accJoiPerShare).div(1e12);
        emit Deposit(msg.sender,msg.value);
    }
    
    
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    //Withdraw token from staking
    
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount,'withdraw: not good');
        updatePool(0);
        
        uint256 pending = user.amount.mul(pool.accJoiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending >0){
            rewardToken.transfer(address(msg.sender),pending);
        }
        
        if(_amount > 0){
            user.amount = user.amount.sub(_amount);
            IWBNB(WBNB).withdraw(_amount);
            safeTransferBNB(address(msg.sender),_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accJoiPerShare).div(1e12);
        emit Withdraw(msg.sender,_amount);
    }
    
    
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.token.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
    
    
    
    
    
    
    
}