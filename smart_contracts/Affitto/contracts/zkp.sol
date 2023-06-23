// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;
import "./Secp256k1.sol";
import "./EllipticCurve.sol";
import "./EllipticCurveFastMult.sol";
//import "./SafeMath.sol";
//import "./SafeMath.sol";

library zkp{


    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function Prover(uint256 x) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
            uint256 r = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % N;
            (uint256 hx,uint256 hy) = EllipticCurve.ecMul(x, GX, GY, AA, PP);
            (uint256 ux,uint256 uy) = EllipticCurve.ecMul(r, GX, GY, AA, PP);         
            uint256 c256 = uint256(uint160(ripemd160(abi.encodePacked(ux,uy,GX,GY,hx,hy)))); 
            uint256 cx = mulmod(x, c256, N);
            bool check= false;
            bool check2=false;
            if (r > N/2){
                    r = r-N/2;
                    check = true;
                    check2= true;
            }
            if (cx > N/2){
                    cx = cx-N/2;
                    check = !check;
                    check2=true;
            }
            uint256 z = 0;
            if (check){
                z = cx + r;
                if (z>N/2){ z -= (N/2+1);}
                else {z += N/2;}    
            }
            else{ 
                    if(check2){z = cx + r - 1;}
                    else {z = cx + r;}}
            return (ux, uy, c256, z, hx, hy);
        }

        function Verifier(uint256 ux, uint256 uy, uint256 c, uint256 z, uint256 hx, uint256 hy) public pure returns (bool){
            (uint256 h_cx, uint256 h_cy) = EllipticCurve.ecMul(c, hx, hy, AA, PP);
            (uint256 point1_x, uint256 point1_y) =  EllipticCurve.ecMul(z, GX, GY, AA, PP);
            (uint256 point2_x, uint256 point2_y) = EllipticCurve.ecAdd(ux, uy, h_cx, h_cy, AA, PP);
            return c ==uint256(uint160(ripemd160(abi.encodePacked(ux,uy,GX,GY,hx,hy))))  && point1_x == point2_x && point1_y == point2_y;
    }

        function test (uint256 x) public view returns (bool){
                (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f) = Prover(x);
                //console.log("prover ok");
                bool v = Verifier(a, b, c, d, e, f);
                return v;
        }
}