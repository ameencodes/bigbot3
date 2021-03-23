pragma solidity ^0.6.6;

import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";
import"./balancer/Bpool.sol";
import"./uniswap/IUniswapV2Router02.sol/


contract Flashloan is FlashLoanReceiverBase {
     using SafeMath for uint256;
    IUniswapV2Router02 uniswapV2Router; //  initialize   smart  contract as variables , same done with Bpool
    Bpool BalancerPool;
    uint deadline;
    IERC20 link;
    address     linkTokenAddress;
    uint256 amountToTrade;
    uint256 tokensOut;

    constructor(address _addressProvider ,IUniswapV2Router02 _uniswapV2Router,  Bpool _BalancerPool)
    ) FlashLoanReceiverBase(_addressProvider) public {
        uniswapV2Router = IUniswapV2Router02(address(_uniswapV2Router));
        BalancerPool =   Bpool(address(_BalancerPool));
        // setting deadline to avoid scenario where miners hang onto it and execute at a more profitable time
            deadline = block.timestamp + 300; // 5 minutes
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");


        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        // run arbitrage stratgey below
        try this.executeArbitrage(){
            catch Error(string memory){

            }
            catch(bytes  memory){

            }
        }
         // return  flash loan + interest fee
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }
    function executeArbitrage() public {
      

        tokenOut =   
    
    // Trade 1: Execute swap of the ERC20 token back from eth into link
        try  BalancerPool.swapExactAmountIn  {  
            value: amountToTrade } (
            getPathForTokenToETH(linkTokenAddress),  // actually change  to ether
            amountToTrade,                              // Trades an exact tokenAmountIn of tokenIn taken from the caller by the pool, in exchange for at least minAmountOut of tokenOut given to the caller from the pool, with a maximum marginal price of maxPrice.
            address tokenOut,
             uint minAmountOut,
            uint maxPrice 
        ){
        } catch {
            // error handling when arb failed due to trade 2    
        }
    }
// Trade 2: Execute swap of Ether into designated ERC20 token on UniswapV2  , which  in this case is link
    try uniswapV2Router.swapExactTokensForETH(
             
             amountToTrade, 
            getPathForETHToToken(linkTokenAddress), 
            address(this), 
            deadline
    ){
        catch {
            // error handling when arb failed due to trade 2    
        }
    }


    }
 
    /**
        sweep entire balance on the arb contract back to contract owner
     */

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset) public onlyOwner {
        bytes memory data = "";
        uint amount = 1 ether;

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }

    Using a WETH wrapper here since there are no direct ETH pairs in Uniswap v2
        and sushiswap v1 is based on uniswap v2
     */
    function getPathForETHToToken(address ERC20Token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = ERC20Token;
    
        return path;
    }

    /**
        Using a WETH wrapper to convert ERC20 token back into ETH
     */
     function getPathForTokenToETH(address ERC20Token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = ERC20Token;
        path[1] = sushiswapV1Router.WETH();
        
        return path;
    }

    /**
        helper function to check ERC20 to ETH conversion rate
     */
    function getEstimatedETHForToken(uint _tokenAmount, address ERC20Token) public view returns (uint[] memory) {
        return uniswapV2Router.getAmountsOut(_tokenAmount, getPathForTokenToETH(ERC20Token));
    }
}
}
