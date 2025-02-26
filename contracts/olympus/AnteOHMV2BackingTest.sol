// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
import "../AnteTest.sol";
import "../interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IOlympusAuthority.sol";

/// @title OlympusDAO OHMv2 supply fully backed by Olympus treasury
/// @notice Ante Test to check Olympus treasury balance exceeds the OHMv2 token supply
/// @dev OHM Backing formula: https://docs.olympusdao.finance/main/references/equations#backing-per-ohm
contract AnteOHMv2BackingTest is AnteTest("Olympus OHMv2 fully backed by treasury reserves") {
    IERC20 public ohm;
    ITreasury public treasury;
    address[] public liquidityTokens;
    address[] public reserveTokens;

    /// @param _treasuryAddress Olympus TreasuryV2 contract address (0x9A315BdF513367C0377FB36545857d12e85813Ef) on mainnet)
    /// @param _ohmAddress Olympus OHMv2 Token contract address (0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5 on  mainnet)
    /// @param _liquidityTokens array of approved liquidity tokens in the Olympus treasury,
    /// currently only 0xb612c37688861f1f90761dc7f382c2af3a50cc39)
    /// @param _reserveTokens array of approved reserve tokens in the Olympus treasury,
    /// currently 0x853d955acef822db058eb8505911ed77f175b99e and 0x6b175474e89094c44da98b954eedeac495271d0f
    constructor(
        address _treasuryAddress,
        address _ohmAddress,
        address[] memory _liquidityTokens,
        address[] memory _reserveTokens
    ) {
        ohm = IERC20(_ohmAddress);
        treasury = ITreasury(_treasuryAddress);

        protocolName = "OlympusDAO";
        testedContracts = [_ohmAddress, _treasuryAddress];

        liquidityTokens = _liquidityTokens;
        reserveTokens = _reserveTokens;
    }

    /// @notice convenience method for getting treasury interface from authority
    /// @return current treasury address initialized as ITreasury interface
    function olympusVault() public view returns (ITreasury) {
        return treasury;
    }

    /// @notice test to check OHMv2 token supply against total treasury reserves
    /// @return true Olympus treasury reserves exceed OHMv2 supply
    function checkTestPasses() external view override returns (bool) {
        uint256 reserves;

        for (uint256 i = 0; i < reserveTokens.length; i++) {
            if (treasury.permissions(ITreasury.STATUS.RESERVETOKEN, reserveTokens[i])) {
                reserves += treasury.tokenValue(
                    reserveTokens[i],
                    IERC20(reserveTokens[i]).balanceOf(address(treasury))
                );
            }
        }

        for (uint256 i = 0; i < liquidityTokens.length; i++) {
            if (treasury.permissions(ITreasury.STATUS.LIQUIDITYTOKEN, liquidityTokens[i])) {
                reserves += treasury.tokenValue(
                    liquidityTokens[i],
                    IERC20(liquidityTokens[i]).balanceOf(address(treasury))
                );
            }
        }

        return reserves >= ohm.totalSupply();
    }
}
