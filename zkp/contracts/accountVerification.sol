// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./ECDSA.sol";
import "./Secp256k1.sol";
import "./EllipticCurve.sol";
import "./EllipticCurveFastMult.sol";

//import "hardhat/console.sol";

contract accountVerification{
    
    function getPub_kFromPriv_k(bytes32 pr_k) public pure returns(bytes32, bytes32){
            //uint256 GX=Secp256k1.getGX();
            (uint256 pub_key_x, uint256 pub_key_y) = EllipticCurve.ecMul(uint256(pr_k), Secp256k1.getGX(), Secp256k1.getGY(), Secp256k1.getAA(), Secp256k1.getPP());
            return (bytes32(pub_key_x), bytes32(pub_key_y));
            
    }

    function getAddressFromPub_k(bytes32 x, bytes32 y) public pure returns (bytes20){
        string memory x_s = string(abi.encodePacked(x));
        string memory y_s = string(abi.encodePacked(y));
        bytes32 hash = (keccak256(abi.encodePacked(x_s,y_s)));
        uint160 u_hash = uint160(uint256(hash) % 2**160);
        return bytes20(u_hash);
    }

    function verify(bytes32 pr_k, address a) public pure returns(bool){
        (bytes32 pub_key_x, bytes32 pub_key_y) = getPub_kFromPriv_k(pr_k);
        bytes20 addr = getAddressFromPub_k(pub_key_x, pub_key_y);
        return a==address(addr);
    }

   /* function test(bytes32 b) public pure returns (bytes20){
        (bytes32 x, bytes32 y) = getPub_kFromPriv_k(b);
        return getAddressFromPub_k(x, y);
    } */
}