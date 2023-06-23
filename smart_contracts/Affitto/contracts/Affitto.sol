// SPDX-License-Identifier: GPL - 3.0

pragma solidity >= 0.7.0;
import "hardhat/console.sol";

/**
    @title fgndfgn
    
*/

contract Affitto {

    // emitted in case the fallback or receive functions get invoked
    event Log(string func, address sender, uint256 value, bytes data);

    /* 
    */
    struct contract_instance {
        uint256 contract_id;
        uint256 room_id;
        bool student_paid;
        bool renter_paid;
        uint256 amt_paid_student;
        uint256 amt_paid_renter;
        bool concluded_student;
        bool concluded_renter;
        address payable student;
        address payable renter;
    }

    /*  id: room id
        owner: address of the room's owner
        occupied: indicates whether the room is already occupied or not
        deposit: amount of money to pay as a deposit for the room
    */
    struct room {
        uint256 id;
        address owner;
        bool occupied;
        uint256 deposit;
    }

    /*  role: specifies the role of the user, who can be either a student or a renter
        contract_instance_record: keeps track of the contract instances the user is currently a part of. 
                                  A student can only participate in one contract instance at a time
        num_rooms: number of rooms that a user owns. A student can't own any room
        already init: says if the address is already registered as a user
    
    The bool variable already_init is used to check if the couple (key, struct) has already been explicitely set.
    This is necessary because Solidity automatically assigns default values even if a key has not been explicitely set and 
    this creates problems when it comes to checking if an address is already registered as a user
    */
    struct user {
        Role role;
        uint256[] contract_instance_record;
        uint256 num_rooms;
        bool already_init;
    }

    enum Role {
        Renter,
        Student
    }

    // associates to each contract id the respective contract record
    mapping(uint256 => contract_instance) contract_record;
    //uint256[] contract_record_keys;

    // associates to each address its respective user information
    mapping(address => user) user_info;  
    //address[] user_info_keys;

    // associates to each renter an array that contains their rooms' id                 
    mapping(address => uint256[]) renters_rooms;                
    //address[] renters_rooms_keys;

    // associates to each room id the corresponding room information
    mapping(uint256 => room) rooms_record;
    //uint256[] rooms_record_keys; 
    
    // conversion rate from eur to wei
    uint256 conversion_rate = 586099570929370;  

    // global variable that is used to assign unique ids to contract instances                   
    uint256 num_contracts;                                         

    constructor() {
        num_contracts = 0;
    }

    /* @param role_id A boolean indicating whether the user is registering as a renter (true) or a student (false)
       
       The function allows the user to register either as a renter or a student. The function prevents double registrations by checking the 'already init' field
       in the user struct. 
    
    */
    function register_user(bool role_id) public {
        // Doesn't allow double registrations
        require(!user_info[msg.sender].already_init, "User already registered");
        uint256[] memory array;
        // false --> student, true --> renter
        if (role_id) {
            user_info[msg.sender] = user({
                role: Role.Renter, 
                contract_instance_record: array, 
                num_rooms: 0, 
                already_init: true
            });
            //user_info_keys.push(msg.sender);
        }
        else {
            user_info[msg.sender] = user({
                role: Role.Student, 
                contract_instance_record: array, 
                num_rooms: 0, 
                already_init: true
            });
            //user_info_keys.push(msg.sender);
        }
        
    }

    /*  @param rooms Array with the rooms ids
        @param deposits The deposit to pay for the corresponding room

        The renter can register several rooms at once by providing the ids of the rooms, it adds the new room structs to the rooms_record_mapping
    */

    function register_rooms(uint256[] memory rooms, uint256[] memory deposits) public {
        // controlliamo che il chiamante sia un renter
        require(user_info[msg.sender].role == Role.Renter, "You are not a renter therefore you're not allowed to register rooms");
        require(rooms.length == deposits.length, "Inconsistent information provided.");
        uint256 l = rooms.length;
        user_info[msg.sender].num_rooms += l; 

        for (uint256 i = 0; i < l; i++) {
            room memory new_room = room({id: rooms[i], owner: msg.sender, occupied: false, deposit: deposits[i]});
            renters_rooms[msg.sender].push(rooms[i]);
            rooms_record[new_room.id] = new_room;
            //rooms_record_keys.push(new_room.id);
        }
        
    }   
    /*
    
    */
    // If the student has his heart already set on a specific room 
    function initialize(address payable renter, uint256 room_id) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");
        require(user_info[msg.sender].role == Role.Student, "You are not a student");
        require(user_info[renter].role == Role.Renter, "The address provided does not correspond to a renter");

        address payable student = payable(msg.sender);
        
        // check che lo studente non sia già in una "istanza" di contratto o che la stanza non sia già occupata
        require(check_if_already_in_contract(student, room_id) == false, "Student or room already in contract"); // controllare che l'inizializzazione venga interrotta e venga emesso il messaggio di errore
        
        // check that the renter is the room's owner
        require(rooms_record[room_id].owner == renter, "Inconsistency between room owner and renter");

        // se né lo student né la stanza sono già in un contratto, possiamo procedere alla creazione della struct che rappresenta l'istanza del contratto
        uint256 new_id = num_contracts;
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
        //contract_record_keys.push(new_id);
        user_info[student].contract_instance_record.push(new_id);
        user_info[renter].contract_instance_record.push(new_id);
    }

    // if the student doesn't care about which room he gets assigned
    function initialize(address payable renter) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");
        require(user_info[msg.sender].role == Role.Student, "You are not a student");
        require(user_info[renter].role == Role.Renter, "The address provided does not correspond to a renter");
        address payable student = payable(msg.sender);

        
        
        uint256 room_id;
        bool room_found = false;

        // Checks if the owner has any rooms available
        for (uint256 i = 0; i < user_info[renter].num_rooms; i++) {
            if (!rooms_record[renters_rooms[renter][i]].occupied) {
                room_found = true;
                room_id = rooms_record[renters_rooms[renter][i]].id;
                break;
            }
        }
        
        require(room_found, "This renter's rooms are all already occupied"); 

        // check che lo studente non sia già in una "istanza" di contratto o che la stanza non sia già occupata
        require(check_if_already_in_contract(student, room_id) == false, "Student or room already in contract"); // controllare che l'inizializzazione venga interrotta e venga emesso il messaggio di errore

        uint256 new_id = num_contracts;
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
        //contract_record_keys.push(new_id);
        user_info[student].contract_instance_record.push(new_id);
        user_info[renter].contract_instance_record.push(new_id);

    
    }

    
    function student_pay_deposit() public payable {
        Role role = user_info[msg.sender].role;
        require(role == Role.Student);
        
        uint256 contract_id = user_info[msg.sender].contract_instance_record[0];
        //console.log(contract_id);
        contract_instance memory instance = contract_record[contract_id];
        uint256 deposit = rooms_record[instance.room_id].deposit;
        uint256 paid_amount = msg.value;
        uint256 amt_to_pay = conversion_rate * deposit;
        //console.log("Paid amount", paid_amount);
        //console.log("Amount to pay", amt_to_pay);
        require((amt_to_pay - 100000) <= paid_amount && paid_amount <= (amt_to_pay + 100000), "Wrong amount paid");
        
        instance.amt_paid_student = paid_amount;
        instance.student_paid = true;
        contract_record[contract_id] = instance;
        
    }

    function renter_pay_deposit(uint256 contract_id) public payable {
        uint256 renter_deposit = 100;
        contract_instance memory instance = contract_record[contract_id];
        Role role = user_info[msg.sender].role;
        require(role == Role.Renter, "Data inconsistency"); // probabilmente inutile (già implicitamente incluso nel secondo require)
        require(msg.sender == instance.renter, "Data inconsistency");
        uint256 paid_amount = msg.value;
        uint256 amt_to_pay = renter_deposit * conversion_rate;
        require((amt_to_pay - 100000) <= paid_amount && paid_amount <= (amt_to_pay + 100000), "Wrong amount paid"); 
        instance.amt_paid_renter = paid_amount;
        instance.renter_paid = true;
        contract_record[contract_id] = instance;    
    }

    function withdraw_from_contract(uint256 contract_id) public {
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
        uint256 room_id = instance.room_id;

        delete_contract_instance(receder, other, contract_id, room_id);
        
        
        payable(other).transfer(instance.amt_paid_student + instance.amt_paid_renter);
    }

    

    function end_contract_successfully(uint256 contract_id) public payable returns (bool) {
        contract_instance memory instance = contract_record[contract_id];
        // require(instance.student_paid, "Student has yet to pay");
        // require(instance.renter_paid, "Renter has yet to pay");
        address student;
        address renter;
        if (user_info[msg.sender].role == Role.Student) {
            student = msg.sender;
            require(instance.student == student);
            instance.concluded_student = true;
            renter = instance.renter;
        }
        else if (user_info[msg.sender].role == Role.Renter){
            renter = msg.sender;
            require(instance.renter == renter);
            instance.concluded_renter = true;
            student = instance.student;
        }

        if (instance.concluded_renter && instance.concluded_student) {
            payable(renter).transfer(instance.amt_paid_student);
            payable(renter).transfer(instance.amt_paid_renter);
            delete_contract_instance(student, renter, contract_id);
            return true;
        }
        else {
            contract_record[contract_id] = instance;
            return false;
        }
    }


    function get_user_info(address add) public view returns (bool, uint256[] memory, uint256, bool) {
        user memory u = user_info[add];
        bool role;
        if (u.role == Role.Renter) {
            role = true;
        }
        else {
            role = false;
        }
        uint256[] memory contract_instance_record = u.contract_instance_record;
        uint256 num_rooms = u.num_rooms;
        bool already_init = u.already_init;
        return (role, contract_instance_record, num_rooms, already_init);
    }

    function get_room_list(address a) public view returns (uint256[] memory) {
        return renters_rooms[a];
    }

    function get_contract_info(uint256 contract_id) public view returns (uint256, uint256, bool, bool, uint256, uint256, bool, bool, address, address) {
        contract_instance memory instance = contract_record[contract_id];
        return (contract_id, instance.room_id, instance.student_paid, instance.renter_paid, instance.amt_paid_student, instance.amt_paid_renter, instance.concluded_student, instance.concluded_renter, instance.student, instance.renter);
    }

    function get_deposit_in_wei(uint256 room_id) public view returns (uint256){
        uint256 deposit = rooms_record[room_id].deposit;
        return (deposit * conversion_rate);
    }

    function get_room_info(uint256 room_id) public view returns (uint256, address, bool, uint256) {
        room memory r = rooms_record[room_id];
        uint256 id = r.id;
        address owner = r.owner;
        bool occupied = r.occupied;
        uint256 deposit = r.deposit;
        return (id, owner, occupied, deposit);
    }

    /* function get_user_info_map() public view {
        for (uint256 i = 0; i < user_info_keys.length; i++) {
            if (user_info[user_info_keys[i]].role == Role.Student) {
                //console.log(user_info_keys[i], false);
            }
            else {
                //console.log(user_info_keys[i], true);
            }
            
        }
    
    } */

    /* function get_contract_record() public view {
        for (uint256 i = 0; i < contract_record_keys.length; i++) {
            (uint256 a, uint256 b, bool c, bool d, uint256 e, uint256 f, bool g, bool h, address j, address k) = get_contract_info(contract_record_keys[i]);
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

    function check_if_already_paid(address addr, uint256 contract_id) public view returns (bool) {
        Role role = user_info[addr].role;
        contract_instance memory instance = contract_record[contract_id];
        if (role == Role.Renter) {
            //console.log("Role: ", true);
            //console.log("Instance renter: ", instance.renter);
            require(addr == instance.renter, "Data inconsistency 1");
            return instance.renter_paid;
        }
        else {
            //console.log("Role: ", false);
            //console.log("Instance student: ", instance.student);
            require(addr == instance.student, "Data inconsistency 2");
            return instance.student_paid;
        }
    }


    function check_if_already_in_contract(address student, uint256 room_id) private view returns (bool) {
        // controlla se lo studente o la stanza (disgiunzione inclusiva) sono già in un contratto
        
        uint256[] memory student_array = user_info[student].contract_instance_record;

        if (student_array.length > 0 || rooms_record[room_id].occupied == true) {
            return true;
        }
        return false;

    }

    function check_user_already_registered(address add) private view returns (bool) {
        return user_info[add].already_init;
    } 

    function delete_contract_instance(address a1, address a2, uint256 contract_id, uint256 room_id) private {
        
        // delete the contract instance
        delete(contract_record[contract_id]);
        //remove(contract_record_keys, contract_id);

        // mark the room as not occupied
        rooms_record[room_id].occupied = false;
        
        // modify the list of contract instances the addresses are a part of
        uint256[] memory a1_record = user_info[a1].contract_instance_record;
        uint256[] memory a1_new_record; // la lunghezza è uno in meno perché tolgo l'id di contratto dall'array
        uint256[] memory a2_record = user_info[a2].contract_instance_record;
        uint256[] memory a2_new_record;


        for (uint256 i = 0; i < a1_record.length; i++) {
            if (a1_record[i] != contract_id) {
                a1_new_record[i] = a1_record[i];
            }  
        }
        user_info[a1].contract_instance_record = a1_new_record; 

        for (uint256 i = 0; i < a2_record.length; i++) {
            if (a2_record[i] != contract_id) {
                a2_new_record[i] = a2_record[i];
            }  
        }
        user_info[a2].contract_instance_record = a2_new_record;
    }

    // the contract ends successfully 
    // the difference with the other delete_contract_instance is that the room doesn't get marked as free
    function delete_contract_instance(address a1, address a2, uint256 contract_id) private {
        
        // delete the contract instance
        delete(contract_record[contract_id]);
        //remove(contract_record_keys, contract_id);
        
        // modify the list of contract instances the addresses are a part of
        uint256[] memory a1_record = user_info[a1].contract_instance_record;
        uint256[] memory a1_new_record; // la lunghezza è uno in meno perché tolgo l'id di contratto dall'array
        uint256[] memory a2_record = user_info[a2].contract_instance_record;
        uint256[] memory a2_new_record;


        for (uint256 i = 0; i < a1_record.length; i++) {
            if (a1_record[i] != contract_id) {
                a1_new_record[i] = a1_record[i];
            }  
        }
        user_info[a1].contract_instance_record = a1_new_record; 

        for (uint256 i = 0; i < a2_record.length; i++) {
            if (a2_record[i] != contract_id) {
                a2_new_record[i] = a2_record[i];
            }  
        }
        user_info[a2].contract_instance_record = a2_new_record;
    }  

    fallback() external payable {
        emit Log("fallback", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value, "");
    }

    function remove(uint256[] storage array, uint256 element) private {
        uint256 index;
        bool found = false;
        for(uint256 i = 0; i < array.length; i++) {
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
        uint256 index;
        bool found = false;
        for(uint256 i = 0; i < array.length; i++) {
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
