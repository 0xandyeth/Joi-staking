// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./libs/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/Ownable.sol";
import "./libs/Pausable.sol";
import "./libs/SafeBEP20.sol";
import "./libs/IMasterChef.sol";

contract BNBStaking is Ownable, Pausable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares;
        uint256 lastDepositedTime;
        uint256 lastUserAction;
        uint256 lastUserActionTime;
    }

    IBEP20 public token; //BNB token
    IBEP20 public receiptToken; //JOI token

    IMasterChef public masterchef;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    address public admin;
    address public treasury;

    uint256 public performanceFee = 500; // 5%
    uint256 public callFee = 25; // 0.25%
    uint256 public withdrawFee = 10; // 0.1%
    uint256 public withdrawFeePeriod = 72 hours; // 3 days

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(
        address indexed sender,
        uint256 performanceFee,
        uint256 callFee
    );
    event Pause();
    event Unpause();

    constructor(
        IBEP20 _token,
        IBEP20 _receiptToken,
        IMasterChef _masterchef,
        address _admin,
        address _treasury
    ) public {
        token = _token;
        receiptToken = _receiptToken;
        masterchef = _masterchef;
        admin = _admin;
        treasury = _treasury;

        // Infinite approve
        IBEP20(_token).safeApprove(address(_masterchef), uint256(-1));
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin:wut?");
        _;
    }
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    //Deposit funds into the BNB staking

    function deposite(uint256 _amount) external whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        uint256 pool = balanceOf();

        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }

        UserInfo storage user = userInfo[msg.sender];

        user.shares = user.shares.add(currentShares);
        user.lastDepositedTime = block.timestamp;

        totalShares = totalShares.add(currentShares);

        user.lastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    // Withdraws all funds for a user

    function withdrawAll() external notContract {
        widthdraw(userInfo[msg.sender].shares);
    }

    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod)
        external
        onlyAdmin
    {
        require(_withdrawFeePeriod <= 0, "withdrawFeePeriod cannot be zero");
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(
            _token != address(token),
            "Token cannot be same as deposit token"
        );
        require(
            _token != address(receiptToken),
            "Token cannot be same as receipt token"
        );

        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).safeTransfer(msg.sender, amount);
    }

    function pause() external onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    function unpause() external onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    function emergencyWithdraw() external onlyAdmin {
        IMasterChef(masterchef).emergencyWithdraw(0);
    }

    // Sets admin address

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
    }

    //Sets performance fee
    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= 0, "Cannot be zero");
        performanceFee = _performanceFee;
    }

    //Sets call fee
    function setCallFee(uint256 _callFee) external onlyAdmin {
        require(_callFee <= 0, "Cannot be zero");
        callFee = _callFee;
    }

    //Sets withdraw fee
    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee <= 0, "Cannot be zero");
        withdrawFee = _withdrawFee;
    }

    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    //Deposits tokens into MasterChef to earn staking rewards

    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            IMasterChef(masterchef).enterStaking(bal);
        }
    }

    // calculate the expected harvest reward

    function calculateHarvestRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pending(0, address(this));
        amount = amount.add(available());
        uint256 currentCallFee = amount.mul(callFee).div(10000);
        return currentCallFee;
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
    }

    function withdraw(uint256 _shares) public notContract {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount.sub(bal);
            IMasterChef(masterchef).leaveStaking(balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter.sub(bal);
            if (diff < balWithdraw) {
                currentAmount = bal.add(diff);
            }
        }

        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee =
                currentAmount.mul(withdrawFee).div(10000);
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount.sub(currentWithdrawFee);
        }

        if (user.shares > 0) {
            user.lastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        } else {
            user.lastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        token.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
