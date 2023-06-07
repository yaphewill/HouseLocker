// SPDX-License-Identifier: GPL - 3.0
pragma solidity >= 0.7.0;

//import "hardhat/console.sol"; // CAPIRE COME IMPORTARE

contract Prova {
    struct contractInstance {
        uint id;
        address payable student;
        address payable renter;
    }

    mapping(uint => contractInstance) contractRecord;
    uint[] contractIds;
    uint caparra = 500; // concetto: stabilire una somma fissa per la caparra
    uint numContracts; // var globale che incremento a ogni nuovo contratto e la uso come id

    constructor() {
        //contractRecord = new mapping(uint => contractInstance); // non chiaro come si inizializza
        numContracts = 0;
        contractIds = new uint[](0); // capire che dimensione mettere, se fa un resize automatico, ecc
    }

    function inizialize(address payable r) public {

        // check che entrambe le parti non siano già in una "istanza" di contratto
        require(checkIfAlreadyInContract(msg.sender, r) == false, "Student or renter already in contract"); // controllare che l'inizializzazione venga interrotta e venga emesso il messaggio di errore

        // se né lo student né il renter sono già in un contratto, possiamo procedere alla creazione della struct che rappresenta l'istanza del contratto
        uint new_id = numContracts;
        numContracts++;
        contractInstance memory instance = contractInstance({id: new_id, student: payable(msg.sender), renter: r});
        contractRecord[new_id] = instance;
        contractIds.push(new_id);
    }
 
    function checkIfAlreadyInContract(address student, address renter) private view returns (bool) { // vedere se c'è un modo computazionalmente più economico per farlo
        uint l = contractIds.length;
        bool alreadyInContract = false;
        for (uint i = 0; i < l; i++) {
            uint curr_id = contractIds[i];
            contractInstance memory curr_contract = contractRecord[curr_id];
            if (curr_contract.student == student || curr_contract.renter == renter) {
                alreadyInContract = true;
                break;
            }
        }
        return alreadyInContract;
    }


// TUTTO LASCIATO UN PO' A CASO
    
}


// problema per i noi del futuro: come assicurarsi che una persona stia partecipando a un solo contratto per volta --> FATTO BITCHES