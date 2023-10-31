# HouseLocker
At the moment, the contract 'Affitto.sol' does not compile. This is because we stumbled upon the EIP 170 (24576 bytes contract 
size limit) introduced with the Spurious Dragon Ethereum hardfork in 2016. <br> 
This is also the reason why several functions that were previously overloaded as a design choice to make the code more elegant have 
now been condensed in one function (initialize and delete_contract_instance), as well as the reason why most of the getters that were
considered not essential for testing have been commented. <br>
The contract can still be tested in Remix providing all the parameters and callings to zkp and accountVerification have previously been 
commented (in that way the contract size does not exceed the limit). <br>
These functionalities can still be tested separately. <br>
We are sorry for the inconvenience but we weren't able to split Affitto in multiple contracts.
# About The Contributors
This was the final project for our "Blockchain" course, the members of the project were four: the three contributors you see plus another 
student [William R. Duro](https://github.com/yaphewill) who didn't have a GitHub account at the time. Basically, all the additions and changes to the code sent 
by [Federico Valbusa](https://github.com/FedericoValbusa) were made together with the other student.
# Link to the Original Project
[HouseLocker](https://github.com/davipase/HouseLocker)
