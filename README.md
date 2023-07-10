# HouseLocker
As if, the contract 'Affitto.sol' does not compile. This is because we stumbled upon the 24576 bytes contract 
size limit introduced with the Spurious Dragon hardfork in 2016. 
This is also the reason why several functions that were previously overloaded as a design choice to make the code more elegant have now been condensed in
one function (initialize and delete_contract-instance).
The contract can still be tested in remix providing all the parameters and callings to zkp and accountVerification have been commented.
These functionalities can still be tested separately.
We are sorry for the inconvenience but we weren't able to split Affitto in multiple contracts.
