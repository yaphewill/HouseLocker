// SPDX-License-Identifier: GPL - 3.0
pragma solidity >= 0.7.0;

//import "hardhat/console.sol"; // CAPIRE COME IMPORTARE

contract Prova {

    struct contract_instance {
        uint contract_id;
        string room_id;
        bool student_paid;
        bool renter_paid;
        address payable student;
        address payable renter;
    }

    struct room {
        string id;
        address owner;
        bool occupied;
    }

    // the bool variable already_init is used to check if the couple (key, struct) has already been explicitely set (to )
    struct user {
        Role role;
        uint[] address_record;
        uint num_rooms;
        bool already_init;
    }

    enum Role {
        Renter,
        Student
    }

    address payable contract_address = payable(address(this));
    mapping(uint => contract_instance) contract_record;         // associa a ogni id la rispettiva struct di contratto
    mapping(address => user) user_info;                        // associa a ogni indirizzo il suo ruolo (student: 0, renter: 1)
    mapping(address => mapping(uint256 => room)) renters_rooms;                  // associa a ogni renter un array che contiene l'id (o NFT, chissà) delle sue stanze
    mapping(string => room) rooms_record;
    uint[] contract_ids;    
    uint conversion_rate = 586099570929370; 
    uint caparra = 200;                                         // si può stabilire una somma fissa per la caparra oppure farla scegliere al renter (?)
    uint num_contracts;                                         // var globale che incremento a ogni nuovo contratto e la uso come id

    constructor() {
        //contract_record = new mapping(uint => contract_instance); // non chiaro come si inizializza
        num_contracts = 0;
        contract_ids = new uint[](0); // capire che dimensione mettere, se fa un resize automatico, ecc
    }

    function create_user(bool role_id) public {
        // Doesn't allow double registrations
        require(!user_info[msg.sender].already_init, "User already registered");
        uint256[] memory a = new uint256[](3);
        // false --> student, true --> renter
        if (role_id) {
            user_info[msg.sender] = user({role: Role.Renter, address_record: a, num_rooms: 0, already_init: true});
        }
        else {
            user_info[msg.sender] = user({role: Role.Student, address_record: a, num_rooms: 0, already_init: true});
        }
        
    }

    function register_rooms(string[] memory rooms) public {
        // controlliamo che il chiamante sia un renter
        require(user_info[msg.sender].role == Role.Renter, "You are not a renter therefore you're not allowed to register rooms");
        
        uint l = rooms.length;
        user_info[msg.sender].num_rooms = l; 
        // TODO: VERIFICARE CHE IL RENTER SIA EFFETTIVAMENTE IL PROPRIETARIO DELLE STANZE (sia fa una zkp nelle nft? chi lo sa)

        for (uint i = 0; i < l; i++) {
            room memory new_room = room({id: rooms[i], owner: msg.sender, occupied: false});
            renters_rooms[msg.sender][i] = new_room;
        }
        
    }   

    // If the student has his heart already set on a specific room 
    function inizialize(address payable renter, string calldata room_id) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");

        address payable student = payable(msg.sender);
        
        // check che lo studente non sia già in una "istanza" di contratto o che la stanza non sia già occupata
        require(check_if_already_in_contract(student, room_id) == false, "Student or room already in contract"); // controllare che l'inizializzazione venga interrotta e venga emesso il messaggio di errore
        
        // check that renter is the room owner
        require(rooms_record[room_id].owner == renter, "Inconsistency between room owner and renter");

        // se né lo student né la stanza sono già in un contratto, possiamo procedere alla creazione della struct che rappresenta l'istanza del contratto
        uint new_id = num_contracts;
        num_contracts++;
        rooms_record[room_id].occupied = true;
        contract_instance memory instance = contract_instance({contract_id: new_id, room_id: room_id, student_paid: false, renter_paid: false, student: student, renter: renter});
        contract_record[new_id] = instance;
        contract_ids.push(new_id);
        user_info[student].address_record.push(new_id);
        user_info[renter].address_record.push(new_id);
    }

    // if the student doesn't care about which room he gets assigned
    function inizialize(address payable renter) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");
        address payable student = payable(msg.sender);
        
        string memory room_id = "";
        bool room_found = false;

        // Checks if the owner has any rooms available
        for (uint i = 0; i < user_info[renter].num_rooms; i++) {
            if (!renters_rooms[renter][i].occupied) {
                room_found = true;
                room_id = renters_rooms[renter][i].id;
                break;
            }
        }
        
        require(room_found, "This renter's rooms are all already occupied"); 

        uint new_id = num_contracts;
        num_contracts++;
        rooms_record[room_id].occupied = true;
        contract_instance memory instance = contract_instance({contract_id: new_id, room_id: room_id, student_paid: false, renter_paid: false, student: student, renter: renter});
        contract_record[new_id] = instance;
        contract_ids.push(new_id);
        user_info[student].address_record.push(new_id);
        user_info[renter].address_record.push(new_id);
    
    }

    // customizziamo receive 
    receive() external payable {
        uint paid_amount = msg.value;
        require(paid_amount == conversion_rate * caparra, "Tu vuole inculale meeee");
        address payer = msg.sender;
        uint l = contract_ids.length;
        for (uint i = 0; i < l; i++) {
            uint curr_id = contract_ids[i];
            contract_instance memory curr_contract = contract_record[curr_id];
            if (curr_contract.student == payer) {
                curr_contract.student_paid = true;
                break;
            }
            else if (curr_contract.renter == payer) {
                curr_contract.renter_paid = true;
            }
        }

    }



    function get_user_info(address add) public view returns (user memory) {
        return user_info[add];
    }

    function get_contract_info(uint256 contract_id) public view returns (contract_instance memory) {
        return contract_record[contract_id];
    }

    function get_contracts_ids() public view returns (uint[] memory) {
        return contract_ids;
    }

    function get_room_info(string memory room_id) public view returns (room memory) {
        return rooms_record[room_id];
    }


    function check_if_already_in_contract(address student, string calldata room_id) private view returns (bool) {
        // controlla se lo studente o la stanza (disgiunzione inclusiva) sono già in un contratto
        
        uint[] memory student_array = user_info[student].address_record;

        if (student_array.length > 0 || rooms_record[room_id].occupied == true) {
            return true;
        }
        return false;

    }

    function check_user_already_registered(address add) private view returns (bool) {
        return user_info[add].already_init;
    }  
}

