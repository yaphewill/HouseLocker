// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;
import "./Secp256k1.sol";
import "./EllipticCurve.sol";
import "./EllipticCurveFastMult.sol";

//import "hardhat/console.sol"; //used for logger
//import "./SafeMath.sol";

contract zkp{
    uint256 public GX = Secp256k1.getGX();
    uint256 public GY = Secp256k1.getGY();
    uint256 public AA = Secp256k1.getAA();
    uint256 public BB = Secp256k1.getBB();
    uint256 public PP = Secp256k1.getPP();
    uint256 public N = Secp256k1.getN();

    function Prover(uint256 x) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
            uint256 r = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % N;
            
            (uint256 hx,uint256 hy) = EllipticCurve.ecMul(x, GX, GY, AA, PP);
            (uint256 ux,uint256 uy) = EllipticCurve.ecMul(r, GX, GY, AA, PP);
            uint256 c256 = uint256(uint160(ripemd160(abi.encodePacked(ux,uy,GX,GY,hx,hy))));

            uint256 z = r + c256*x;
            return (ux, uy, c256, z, hx, hy);
    }

    function Verifier(uint256 ux, uint256 uy, uint256 c, uint256 z, uint256 hx, uint256 hy) public view returns (bool){
            (uint256 h_cx, uint256 h_cy) = EllipticCurve.ecMul(c, hx, hy, AA, PP);
            (uint256 point1_x, uint256 point1_y) =  EllipticCurve.ecMul(z, GX, GY, AA, PP);
            (uint256 point2_x, uint256 point2_y) = EllipticCurve.ecAdd(ux, uy, h_cx, h_cy, AA, PP);
            //bool bool1 =  c ==uint256(sha256(abi.encodePacked(ux,uy,GX,GY,hx,hy)));
            //console.log(c);
            //console.log(uint256(uint160(ripemd160(abi.encodePacked(ux,uy,GX,GY,hx,hy)))));
            //console.log(point1_x);
            //console.log(point2_x);
            //console.log(point1_y);
            //console.log(point2_y);
            return c ==uint256(uint160(ripemd160(abi.encodePacked(ux,uy,GX,GY,hx,hy))))  && point1_x == point2_x && point1_y == point2_y;
    }

        function test (uint256 x) public view returns (bool){
                (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f) = Prover(x);
                bool v = Verifier(a, b, c, d, e, f);
                return v;
        }
}