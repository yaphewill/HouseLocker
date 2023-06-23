// SPDX-License-Identifier: GPL - 3.0

pragma solidity >= 0.7.0;
//import "hardhat/console.sol";

contract Affitto {

    event Log(string func, address sender, uint value, bytes data);

    struct contract_instance {
        uint contract_id;
        uint room_id;
        bool student_paid;
        bool renter_paid;
        uint amt_paid_student;
        uint amt_paid_renter;
        bool concluded_student;
        bool concluded_renter;
        address payable student;
        address payable renter;
    }

    struct room {
        uint id;
        address owner;
        bool occupied;
        uint deposit;
    }

    // the bool variable already_init is used to check if the couple (key, struct) has already been explicitely set (solidity automatically )
    struct user {
        Role role;
        uint[] room_record;
        uint num_rooms;
        bool already_init;
    }

    enum Role {
        Renter,
        Student
    }

    address payable contract_address = payable(address(this));
    mapping(uint => contract_instance) contract_record;         // associa a ogni id la rispettiva struct di contratto
    uint[] contract_record_keys;
    mapping(address => user) user_info;
    address[] user_info_keys;                        // associa a ogni indirizzo il suo ruolo (student: 0, renter: 1)
    mapping(address => uint[]) renters_rooms;                  // associa a ogni renter un array che contiene l'id delle sue stanze
    address[] renters_rooms_keys;
    mapping(uint => room) rooms_record; 
    uint[] rooms_record_keys;   
    uint conversion_rate = 586099570929370;                     // DA CHIEDERE ALL'ESTERNO?
    uint num_contracts;                                         // var globale che incremento a ogni nuovo contratto e la uso come id

    constructor() {
        //contract_record = new mapping(uint => contract_instance); // non chiaro come si inizializza
        num_contracts = 0;
    }

    function register_user(bool role_id) public {
        // Doesn't allow double registrations
        require(!user_info[msg.sender].already_init, "User already registered");
        uint256[] memory array;
        // false --> student, true --> renter
        if (role_id) {
            user_info[msg.sender] = user({
                role: Role.Renter, 
                room_record: array, 
                num_rooms: 0, 
                already_init: true
            });
            user_info_keys.push(msg.sender);
        }
        else {
            user_info[msg.sender] = user({
                role: Role.Student, 
                room_record: array, 
                num_rooms: 0, 
                already_init: true
            });
            user_info_keys.push(msg.sender);
        }
        
    }

    function register_rooms(uint[] memory rooms, uint[] memory deposits) public {
        // controlliamo che il chiamante sia un renter
        require(user_info[msg.sender].role == Role.Renter, "You are not a renter therefore you're not allowed to register rooms");
        require(rooms.length == deposits.length, "Inconsistent information provided.");
        uint l = rooms.length;
        user_info[msg.sender].num_rooms = l; 
        // TODO: VERIFICARE CHE IL RENTER SIA EFFETTIVAMENTE IL PROPRIETARIO DELLE STANZE (sia fa una zkp nelle nft? chi lo sa)

        for (uint i = 0; i < l; i++) {
            room memory new_room = room({id: rooms[i], owner: msg.sender, occupied: false, deposit: deposits[i]});
            renters_rooms[msg.sender].push(rooms[i]);
            rooms_record[new_room.id] = new_room;
            rooms_record_keys.push(new_room.id);
        }
        
    }   

    // If the student has his heart already set on a specific room 
    function inizialize(address payable renter, uint room_id) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");

        address payable student = payable(msg.sender);
        
        // check che lo studente non sia già in una "istanza" di contratto o che la stanza non sia già occupata
        require(check_if_already_in_contract(student, room_id) == false, "Student or room already in contract"); // controllare che l'inizializzazione venga interrotta e venga emesso il messaggio di errore
        
        // check that the renter is the room's owner
        require(rooms_record[room_id].owner == renter, "Inconsistency between room owner and renter");

        // se né lo student né la stanza sono già in un contratto, possiamo procedere alla creazione della struct che rappresenta l'istanza del contratto
        uint new_id = num_contracts;
        num_contracts++;
        rooms_record[room_id].occupied = true;
        contract_instance memory instance = contract_instance({
            contract_id: new_id, 
            room_id: room_id, 
            student_paid: false, 
            renter_paid: false, 
            amt_paid_student: 0, 
            amt_paid_renter: 0, 
            concluded_student: false, 
            concluded_renter: false, 
            student: student, 
            renter: renter
        });

        contract_record[new_id] = instance;
        contract_record_keys.push(new_id);
        user_info[student].room_record.push(new_id);
        user_info[renter].room_record.push(new_id);
    }

    // if the student doesn't care about which room he gets assigned
    function inizialize(address payable renter) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");
        address payable student = payable(msg.sender);
        
        uint room_id;
        bool room_found = false;

        // Checks if the owner has any rooms available
        for (uint i = 0; i < user_info[renter].num_rooms; i++) {
            if (!rooms_record[renters_rooms[renter][i]].occupied) {
                room_found = true;
                room_id = rooms_record[renters_rooms[renter][i]].id;
                break;
            }
        }
        
        require(room_found, "This renter's rooms are all already occupied"); 

        uint new_id = num_contracts;
        num_contracts++;
        rooms_record[room_id].occupied = true;
        contract_instance memory instance = contract_instance({
            contract_id: new_id, 
            room_id: room_id, 
            student_paid: false, 
            renter_paid: false, 
            amt_paid_student: 0, 
            amt_paid_renter: 0, 
            concluded_student: false, 
            concluded_renter: false, 
            student: student, 
            renter: renter
        });
        contract_record[new_id] = instance;
        user_info[student].room_record.push(new_id);
        user_info[renter].room_record.push(new_id);
    
    }

    
    function student_pay_deposit() public payable {
        Role role = user_info[msg.sender].role;
        require(role == Role.Student);
        
        uint contract_id = user_info[msg.sender].room_record[0];
        contract_instance memory instance = contract_record[contract_id];
        uint deposit = rooms_record[instance.room_id].deposit;
        uint paid_amount = msg.value;
        require(paid_amount == conversion_rate * deposit, "Wrong amount paid");
        
        instance.amt_paid_student = paid_amount;
        instance.student_paid = true;
        contract_record[contract_id] = instance;
        
    }

    function renter_pay_deposit(uint contract_id) public payable {
        contract_instance memory instance = contract_record[contract_id];
        Role role = user_info[msg.sender].role;
        require(role == Role.Renter, "Data inconsistency"); // probabilmente inutile (già implicitamente incluso nel secondo require)
        require(msg.sender == instance.renter, "Data inconsistency");
        uint deposit = rooms_record[instance.room_id].deposit;
        uint paid_amount = msg.value;
        require(paid_amount == conversion_rate * deposit, "Wrong amount paid"); 
        instance.amt_paid_renter = paid_amount;
        instance.renter_paid = true;
        contract_record[contract_id] = instance;    
    }

    function withdraw_from_contract(uint contract_id) public {
        // IDEA: lo studente non può ritirarsi prima di aver pagato la caparra, oppure può ritirarsi gratuitamente nel lasso di tempo 
        // che ha per pagare la caparra
        address receder = msg.sender;
        address other;
        contract_instance memory instance = contract_record[contract_id];
        if (user_info[msg.sender].role == Role.Student) {
            other = contract_record[contract_id].renter;
        }
        else {
            other = contract_record[contract_id].student;
        }
        uint room_id = instance.room_id;

        delete_contract_instance(receder, other, contract_id, room_id);
        
        
        payable(other).transfer(instance.amt_paid_student + instance.amt_paid_renter);
    }

    

    function end_contract_successfully(uint contract_id) public returns (bool) {
        contract_instance memory instance = contract_record[contract_id];
        address student;
        address renter;
        if (user_info[msg.sender].role == Role.Student) {
            student = msg.sender;
            instance.concluded_student = true;
            renter = instance.renter;
        }
        else {
            renter = msg.sender;
            instance.concluded_renter = true;
            student = instance.student;
        }

        if (instance.concluded_renter && instance.concluded_student) {
            delete_contract_instance(student, renter, contract_id);
            payable(student).transfer(instance.amt_paid_student);
            payable(renter).transfer(instance.amt_paid_renter);
            return true;
        }
        return false;
    }


    function get_user_info(address add) public view returns (bool, uint[] memory, uint, bool) {
        user memory u = user_info[add];
        bool role;
        if (u.role == Role.Renter) {
            role = true;
        }
        else {
            role = false;
        }
        uint[] memory room_record = u.room_record;
        uint num_rooms = u.num_rooms;
        bool already_init = u.already_init;
        return (role, room_record, num_rooms, already_init);
    }

    function get_room_list(address a) public view returns (uint[] memory) {
        return renters_rooms[a];
    }

    function get_contract_info(uint256 contract_id) public view returns (uint, uint, bool, bool, uint, uint, bool, bool, address, address) {
        contract_instance memory instance = contract_record[contract_id];
        return (contract_id, instance.room_id, instance.student_paid, instance.renter_paid, instance.amt_paid_student, instance.amt_paid_renter, instance.concluded_student, instance.concluded_renter, instance.student, instance.renter);
    }

    function get_deposit_in_wei(uint room_id) public view returns (uint){
        uint deposit = rooms_record[room_id].deposit;
        return (deposit * conversion_rate);
    }

    function get_room_info(uint room_id) public view returns (uint, address, bool, uint) {
        room memory r = rooms_record[room_id];
        uint id = r.id;
        address owner = r.owner;
        bool occupied = r.occupied;
        uint deposit = r.deposit;
        return (id, owner, occupied, deposit);
    }


    /* function get_contract_record() public view {
        for (uint i = 0; i < contract_record_keys.length; i++) {
            (uint a, uint b, bool c, bool d, uint e, uint f, bool g, bool h, address j, address k) = get_contract_info(contract_record_keys[i]);
            console.log(a);
            console.log(b);
            console.log(c);
            console.log(d);
            console.log(e);
            console.log(f);
            console.log(g);
            console.log(h);
            console.log(j);
            console.log(k);
            console.log("\n");
            console.log("\n");
        }
    } */

    function check_if_already_paid(address addr, uint contract_id) public view returns (bool) {
        Role role = user_info[addr].role;
        contract_instance memory instance = contract_record[contract_id];
        if (role == Role.Renter) {
            require(addr == instance.renter, "Data inconsistency");
            return instance.renter_paid;
        }
        else {
            require(addr == instance.student, "Data inconsistency");
            return instance.student_paid;
        }
    }


    function check_if_already_in_contract(address student, uint room_id) private view returns (bool) {
        // controlla se lo studente o la stanza (disgiunzione inclusiva) sono già in un contratto
        
        uint[] memory student_array = user_info[student].room_record;

        if (student_array.length > 0 || rooms_record[room_id].occupied == true) {
            return true;
        }
        return false;

    }

    function check_user_already_registered(address add) private view returns (bool) {
        return user_info[add].already_init;
    } 

    function delete_contract_instance(address a1, address a2, uint contract_id, uint room_id) private {
        
        // delete the contract instance
        delete(contract_record[contract_id]);
        remove(contract_record_keys, contract_id);

        // mark the room as not occupied
        rooms_record[room_id].occupied = false;
        
        // modify the list of contract instances the addresses are a part of
        uint[] memory a1_record = user_info[a1].room_record;
        uint[] memory a1_new_record; // la lunghezza è uno in meno perché tolgo l'id di contratto dall'array
        uint[] memory a2_record = user_info[a2].room_record;
        uint[] memory a2_new_record;


        for (uint i = 0; i < a1_record.length; i++) {
            if (a1_record[i] != contract_id) {
                a1_new_record[i] = a1_record[i];
            }  
        }
        user_info[a1].room_record = a1_new_record; 

        for (uint i = 0; i < a2_record.length; i++) {
            if (a2_record[i] != contract_id) {
                a2_new_record[i] = a2_record[i];
            }  
        }
        user_info[a2].room_record = a2_new_record;
    }

    // the contract ends successfully 
    // the difference with the other delete_contract_instance is that the room doesn't get marked as free
    function delete_contract_instance(address a1, address a2, uint contract_id) private {
        
        // delete the contract instance
        delete(contract_record[contract_id]);
        remove(contract_record_keys, contract_id);
        
        // modify the list of contract instances the addresses are a part of
        uint[] memory a1_record = user_info[a1].room_record;
        uint[] memory a1_new_record; // la lunghezza è uno in meno perché tolgo l'id di contratto dall'array
        uint[] memory a2_record = user_info[a2].room_record;
        uint[] memory a2_new_record;


        for (uint i = 0; i < a1_record.length; i++) {
            if (a1_record[i] != contract_id) {
                a1_new_record[i] = a1_record[i];
            }  
        }
        user_info[a1].room_record = a1_new_record; 

        for (uint i = 0; i < a2_record.length; i++) {
            if (a2_record[i] != contract_id) {
                a2_new_record[i] = a2_record[i];
            }  
        }
        user_info[a2].room_record = a2_new_record;
    }  


    function check_if_user_already_registered(address addr) private view returns (bool) {
        return user_info[addr].already_init;
    }

    fallback() external payable {
        emit Log("fallback", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Log("fall", msg.sender, msg.value, "");
    }

    function remove(uint[] storage array, uint element) private {
        uint index;
        bool found = false;
        for(uint i = 0; i < array.length; i++) {
            if (array[i] == element) {
                index = i;
                found = true;
                break;
            }
        }
        require(found, "Element not present in array");
        array[index] = array[array.length - 1];
        array.pop();
    }

    function remove(address[] storage array, address element) private {
        uint index;
        bool found = false;
        for(uint i = 0; i < array.length; i++) {
            if (array[i] == element) {
                index = i;
                found = true;
                break;
            }
        }
        require(found, "Element not present in array");
        array[index] = array[array.length - 1];
        array.pop();
    }

}

