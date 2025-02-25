// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

import "../contracts/facets/MiteTokenFacet.sol";
import "../contracts/facets/StakingFacet.sol"; // My staking contraacts;

import "../contracts/facets/LayoutChangerFacet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

import "../contracts/libraries/LibAppStorage.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    LayoutChangerFacet lFacet;
    StakingFacet sFacet;
    MiteTokenFacet tokenF;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        lFacet = new LayoutChangerFacet();
        sFacet = new StakingFacet();
        tokenF = new MiteTokenFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

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
                facetAddress: address(lFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LayoutChangerFacet")
            })
        );
        cut[3] = (
            FacetCut({
                facetAddress: address(sFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StakingFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testLayoutfacet() public {
        LayoutChangerFacet l = LayoutChangerFacet(address(diamond));
        // l.getLayout();
        l.ChangeNameAndNo(777, "one guy");

        //check outputs
        LibAppStorage.Layout memory la = l.getLayout();

        assertEq(la.name, "one guy");
        assertEq(la.currentNo, 777);
    }

    function testLayoutfacet2() public {
        LayoutChangerFacet l = LayoutChangerFacet(address(diamond));
        //check outputs
        LibAppStorage.Layout memory la = l.getLayout();

        assertEq(la.name, "one guy");
        assertEq(la.currentNo, 777);
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
