// SPDX-License-Identifier: GPL - 3.0

pragma solidity >= 0.7.0;
//import "hardhat/console.sol";

/**
    @title Affitto. The contract allows for the registration of a user as either a student or a renter. The student
    can try out the service while the renter can register rooms. The student calls a function
    (contract instance) to enter into a contract with the renter. You can withdraw but the other party takes your money.
    When both parties agree, the contract is successfully terminated and the renter takes both's money (since the student's 
    deposit will serve as an actual deposit for the legal lease).
    
*/

contract Affitto {

    // emitted in case the fallback or receive functions get invoked
    event Log(string func, address sender, uint256 value, bytes data);

    /*  contract_instance contains all the information that needs to get track of when it comes to the contract instance
        contract_id: the contract's uinque id
        room_id: the room's unique id
        student_paid: indicates whether the student has already paid the deposit
        renter_paid: indicates whether the renter has already paid the deposit
        amt_paid_student: amount paid by the student as a deposit. This amount is stored to make it easier when 
                          the contract transfers back the money to the parties
        amt_paid_renter: amount paid by the renter as a deposit. This amount is stored to make it easier when
                          the contract transfers back the money to the parties 
        concluded_student: indicates whether the student has already expressed the will to terminate the contract successfully
        concluded_renter: indicates whether the renter has already expressed the will to terminate the contract successfully 
        student: address of the student
        renter: address of the renter            
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

    // deposit paid by the renter as a guarantee of their good faith
    uint256 renter_deposit;                                   

    constructor() {
        num_contracts = 0;
        renter_deposit = 100;
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
    /*  @param renter The address of the renter
        @param room_id The id of the room

        After performing some checks on the function caller and the renter, the function creates a contract instance with the information provided.
        This function's version takes as a parameter also the room_id, in case the student has their heart already set on a specific room
        
    
    */
    // If the student has his heart already set on a specific room 
    function initialize(address payable renter, uint256 room_id) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(renter), "Renter is not an authorized user");
        require(user_info[msg.sender].role == Role.Student, "You are not a student");
        require(user_info[renter].role == Role.Renter, "The address provided does not correspond to a renter");

        address payable student = payable(msg.sender);
        
        // check that the student is not in a contract instance and that the room is not occupied
        require(check_if_already_in_contract(student, room_id) == false, "Student or room already in contract");
        
        // check that the renter is the room's owner
        require(rooms_record[room_id].owner == renter, "Inconsistency between room owner and renter");

        // if neither the student and the room are already in a contract instance, the function proceeds with the creation of the contract instance
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

    /*  @param renter The address of the renter 

        This version of the function doesn't take the room_id as an info, in case the student doesn't care about which room they get assigned
        The student just gets assigned the first room available
    
    */
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

        // Check that neither the student and the renter are in a contract instance (the student is allowed to participate in only one contract instance at a time)
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

    /*  The function allows the student to pay the deposit for the room he has locked in the contract instance
        The contract allows some tolerance on the amount received as the deposit
    */
    function student_pay_deposit() public payable {
        Role role = user_info[msg.sender].role;
        require(role == Role.Student);
        
        uint256 contract_id = user_info[msg.sender].contract_instance_record[0];
        //console.log(contract_id);
        contract_instance memory instance = contract_record[contract_id];
        uint256 paid_amount = msg.value;
        uint256 amt_to_pay = get_student_deposit_in_wei(instance.room_id);
        //console.log("Paid amount", paid_amount);
        //console.log("Amount to pay", amt_to_pay);
        require((amt_to_pay - 100000) <= paid_amount && paid_amount <= (amt_to_pay + 100000), "Wrong amount paid");
        
        instance.amt_paid_student = paid_amount;
        instance.student_paid = true;
        contract_record[contract_id] = instance;
        
    }

    /*  @param contract_id
        The function allows the student to pay the deposit for one of the rooms that are currently blocked in a contract instance
        The contract allows some tolerance on the amount received as the deposit
    */
    function renter_pay_deposit(uint256 contract_id) public payable {
        uint256 amt_to_pay = get_renter_deposit_in_wei();
        contract_instance memory instance = contract_record[contract_id];
        Role role = user_info[msg.sender].role;
        require(role == Role.Renter, "Data inconsistency"); // probabilmente inutile (già implicitamente incluso nel secondo require)
        require(msg.sender == instance.renter, "Data inconsistency");
        uint256 paid_amount = msg.value;
        require((amt_to_pay - 100000) <= paid_amount && paid_amount <= (amt_to_pay + 100000), "Wrong amount paid"); 
        instance.amt_paid_renter = paid_amount;
        instance.renter_paid = true;
        contract_record[contract_id] = instance;    
    }

    /*  @param contract_id
        The function allows either party to withdraw from their contract
        The function calls an internal function named delete contract instance to delete this contract instance
        and transfer any funds paid by either party to the other party
    */
    function withdraw_from_contract(uint256 contract_id) public {
        address receder = msg.sender;

        address other;
        contract_instance memory instance = contract_record[contract_id];
        if (user_info[msg.sender].role == Role.Student) {
            // require also protects in case contract_id doesn't exist
            require(instance.student == msg.sender, "You tried withdraw from a contract you are not a part of");
            other = contract_record[contract_id].renter;
        }
        else {
            // require also protects in case contract_id doesn't exist
            require(instance.renter == msg.sender, "You tried withdraw from a contract you are not a part of");
            other = contract_record[contract_id].student;
        }
        uint256 room_id = instance.room_id;

        delete_contract_instance(receder, other, contract_id, room_id);
        
        uint256 amt_to_give_back = rooms_record[instance.room_id].deposit * conversion_rate;
        
        payable(other).transfer(amt_to_give_back + instance.amt_paid_renter);
    }

    /*  @param contract_id
        function allows either party to end their contract successfully.
        It updates the contract instance to indicate that the sender has concluded the contract.
        If both parties have concluded the contract, it calls an internal to delete this contract instance
         and transfer any funds paid to the renter
    */
    function end_contract_successfully(uint256 contract_id) public returns (bool) {
        contract_instance memory instance = contract_record[contract_id];
        require(instance.student_paid, "Student has yet to pay");
        require(instance.renter_paid, "Renter has yet to pay");
        address student;
        address renter;
        if (user_info[msg.sender].role == Role.Student) {
            student = msg.sender;
            require(instance.student == student, "You are trying to terminate a contract you are not a part of");
            instance.concluded_student = true;
            renter = instance.renter;
        }
        else if (user_info[msg.sender].role == Role.Renter){
            renter = msg.sender;
            require(instance.renter == renter, "You are trying to terminate a contract you are not a part of");
            instance.concluded_renter = true;
            student = instance.student;
        }

        if (instance.concluded_renter && instance.concluded_student) {
            uint256 amt_to_give_back = rooms_record[instance.room_id].deposit * conversion_rate;
            payable(renter).transfer(amt_to_give_back);
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

    // returns the deposit for the blocked room in wei with the 10% added as the contract's fee for the service
    function get_student_deposit_in_wei(uint256 room_id) public view returns (uint256) {
        uint256 deposit = rooms_record[room_id].deposit;
        uint256 net_amt_in_wei = deposit * conversion_rate;
        uint256 contract_gain = net_amt_in_wei / 10;
        return (net_amt_in_wei + contract_gain); 
    }

    function get_renter_deposit_in_wei() public view returns (uint256) {
        return (renter_deposit * conversion_rate);
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
        // checks if the student or the room are already in a contract instance
        
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
        uint256[] memory a1_new_record; 
        uint256[] memory a2_record = user_info[a2].contract_instance_record;
        uint256[] memory a2_new_record;


        for (uint256 i = 0; i < a1_record.length; i++) {
            if (a1_record[i] != contract_id) {
                //console.log(a1_record[i]);
                a1_new_record[i] = a1_record[i];
            }  
        }
        user_info[a1].contract_instance_record = a1_new_record; 

        for (uint256 i = 0; i < a2_record.length; i++) {
            if (a2_record[i] != contract_id) {
                //console.log(a1_record[i]);
                a2_new_record[i] = a2_record[i];
            }  
        }
        user_info[a2].contract_instance_record = a2_new_record;
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

    fallback() external payable {
        emit Log("fallback", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value, "");
    }
}

