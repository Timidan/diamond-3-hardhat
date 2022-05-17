// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/Vm.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/libraries/LibDiamond.sol";
import "../contracts/facets/OwnershipFacet.sol";

contract ContractTest is Test, IDiamondCut {
    event outByte(bytes i);
    event outByte4(bytes4 i);

    bytes4[] dCutSlector = [
        bytes4(0x6b9a894e),
        0xfc3fc4ed,
        0x5608de71,
        0x5608de71
        // 0x919e84f5,
        // 0xe07bc69c,
        // 0xaefa7d98,
        // 0x14ff5ea3,
        // 0x0facebea,
        // 0xfc3fc4ed,
        // 0x5608de71,
        // 0x919e84f5,
        // 0xe07bc69c,
        // 0xaefa7d98,
        // 0x14ff5ea3,
        // 0x0facebea
    ];
    bytes4[] dCutFunction = [bytes4(0x1f931c1c)];
    bytes4[] notInDiamond = [bytes4(0x14ff5ea3)];
    bytes4[] immutableFunc = [bytes4(0x54353f2f)];

    bytes4[] OWNERSHIP_SELECTORS = [bytes4(0xf2fde38b)];

    DiamondCutFacet dCut;
    Diamond diamond;
    OwnershipFacet oFacet;

    function setUp() public {
        dCut = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCut));
        oFacet = new OwnershipFacet();
    }

    // function testExample() public {
    //     string[] memory inputs = new string[](2);
    //     inputs[0] = "ts-node";
    //     inputs[1] = "genSelectorsss.ts";
    //     bytes memory sss = vm.ffi(inputs);
    //     emit outByte(sss);
    // }

    function testDiamondCutErrors() public {
        ///ADDING SELECTOR ERRORS
        //Not Owner
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = (FacetCut({facetAddress: address(dCut), action: FacetCutAction.Add, functionSelectors: dCutSlector}));
        vm.prank(address(0xbeef));
        vm.expectRevert(LibDiamond.NotDiamondOwner.selector);
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        //Invalid FacetCutAction
        FacetCut[] memory cut2 = new FacetCut[](1);
        cut2[0] = (FacetCut({facetAddress: address(dCut), action: FacetCutAction.Subtract, functionSelectors: dCutSlector}));
        vm.expectRevert(LibDiamond.InValidFacetCutAction.selector);
        IDiamondCut(address(diamond)).diamondCut(cut2, address(0), "");

        //Add a facet with empty selectors
        FacetCut[] memory cut3 = new FacetCut[](1);
        bytes4[] memory emptyS = new bytes4[](0);
        cut3[0] = (FacetCut({facetAddress: address(0xdead), action: FacetCutAction.Add, functionSelectors: emptyS}));
        vm.expectRevert(LibDiamond.NoSelectorsInFacet.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //Add with a zero address facet
        cut3[0] = (FacetCut({facetAddress: address(0), action: FacetCutAction.Add, functionSelectors: dCutSlector}));
        vm.expectRevert(LibDiamond.NoZeroAddress.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //Add a function that already exists
        cut3[0] = (FacetCut({facetAddress: address(dCut), action: FacetCutAction.Add, functionSelectors: dCutFunction}));
        vm.expectRevert(abi.encodeWithSelector(LibDiamond.SelectorExists.selector, bytes4(0x1f931c1c)));
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        ///REPLACING SELECTOR ERRORS
        //replace with a facet without selectors
        cut3[0] = (FacetCut({facetAddress: address(0xdead), action: FacetCutAction.Replace, functionSelectors: emptyS}));
        vm.expectRevert(LibDiamond.NoSelectorsInFacet.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //replace with a facet that has a zero address
        cut3[0] = (FacetCut({facetAddress: address(0), action: FacetCutAction.Replace, functionSelectors: dCutSlector}));
        vm.expectRevert(LibDiamond.NoZeroAddress.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //replace a selector with an identical selector with same facet addresses
        cut3[0] = (FacetCut({facetAddress: address(dCut), action: FacetCutAction.Replace, functionSelectors: dCutFunction}));
        vm.expectRevert(abi.encodeWithSelector(LibDiamond.SameSelectorReplacement.selector, bytes4(0x1f931c1c)));
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        ///REMOVE SELECTOR ERRORS
        //remove a facet with empty selectors
        cut3[0] = (FacetCut({facetAddress: address(0xdead), action: FacetCutAction.Remove, functionSelectors: emptyS}));
        vm.expectRevert(LibDiamond.NoSelectorsInFacet.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //try to remove without passing in a zero address
        cut3[0] = (FacetCut({facetAddress: address(0xdead), action: FacetCutAction.Remove, functionSelectors: dCutSlector}));
        vm.expectRevert(LibDiamond.MustBeZeroAddress.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        ////OTHER ERRORS0x54353f2f
        //Try to remove a function that does not exist
        cut3[0] = (FacetCut({facetAddress: address(0), action: FacetCutAction.Remove, functionSelectors: notInDiamond}));
        vm.expectRevert(abi.encodeWithSelector(LibDiamond.NonExistentSelector.selector, bytes4(0x14ff5ea3)));
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //Try to remove an immutable function
        //Add the function directly to the diamond first
        cut3[0] = (FacetCut({facetAddress: address(diamond), action: FacetCutAction.Add, functionSelectors: immutableFunc}));
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");
        //now try to remove
        cut3[0] = (FacetCut({facetAddress: address(0), action: FacetCutAction.Remove, functionSelectors: immutableFunc}));
        vm.expectRevert(abi.encodeWithSelector(LibDiamond.ImmutableFunction.selector, immutableFunc[0]));
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");
        emit outByte4(diamond.example.selector);

        //add OwnershipFacet normally
        cut3[0] = (FacetCut({facetAddress: address(oFacet), action: FacetCutAction.Add, functionSelectors: OWNERSHIP_SELECTORS}));
        //should revert if calldata is non empty but init address is address 0
        vm.expectRevert(LibDiamond.NonEmptyCalldata.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), abi.encode("rand"));

        //should revert if calldata is empty but init address is not address 0
        vm.expectRevert(LibDiamond.EmptyCalldata.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0xdead), "");

        //Trying to add a non contract as a facet
        cut3[0] = (FacetCut({facetAddress: address(0xdead), action: FacetCutAction.Add, functionSelectors: OWNERSHIP_SELECTORS}));
        vm.expectRevert(LibDiamond.NoCode.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(0), "");

        //A normal failing init delegate call should revert
        cut3[0] = (FacetCut({facetAddress: address(dCut), action: FacetCutAction.Add, functionSelectors: OWNERSHIP_SELECTORS}));
        vm.expectRevert(LibDiamond.InitCallFailed.selector);
        IDiamondCut(address(diamond)).diamondCut(cut3, address(oFacet), abi.encodeWithSelector(0xaefa7d98, 3));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
