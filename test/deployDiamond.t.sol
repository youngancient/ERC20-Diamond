// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    ERC20Facet erc20Facet;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    function testDeployDiamond() public {
        address owner = address(0x333);
        address to = address(0x444);

        vm.startPrank(owner);
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc20Facet = new ERC20Facet();
        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(erc20Facet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC20Facet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        ERC20Facet(address(diamond)).initialize("Don't Disturb", "DND", 18);

        string memory tokenName = ERC20Facet(address(diamond)).name();
        string memory tokenSymbol = ERC20Facet(address(diamond)).symbol();
        assertEq(tokenName, "Don't Disturb");
        assertEq(tokenSymbol, "DND");
        
        // mint
        ERC20Facet(address(diamond)).mint(owner, 1000e18);
        assertEq(ERC20Facet(address(diamond)).balanceOf(owner), 1000e18);

        // transfer
        ERC20Facet(address(diamond)).transfer(to, 400e18);
        assertEq(ERC20Facet(address(diamond)).balanceOf(to), 400e18);
        assertEq(ERC20Facet(address(diamond)).balanceOf(owner), 600e18);

        // burn
        ERC20Facet(address(diamond)).burn(100e18);
        assertEq(ERC20Facet(address(diamond)).totalSupply(), 900e18);

        // approve 
        ERC20Facet(address(diamond)).approve(to, 100e18);
        assertEq(ERC20Facet(address(diamond)).allowance(owner,to), 100e18);

        vm.stopPrank();

        vm.startPrank(to);
        // transferFrom
        ERC20Facet(address(diamond)).transferFrom(owner, to, 100e18);

        assertEq(ERC20Facet(address(diamond)).balanceOf(owner), 400e18);
        assertEq(ERC20Facet(address(diamond)).balanceOf(to), 500e18);
        assertEq(ERC20Facet(address(diamond)).allowance(owner,to), 0);
    }

    // function testNameAndSymbol() public {
        
    // }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
