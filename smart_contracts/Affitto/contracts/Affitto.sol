// SPDX-License-Identifier: GPL - 3.0

pragma solidity >= 0.7.0;

import "./accountVerification.sol";
import "./zkp.sol";
//import "hardhat/console.sol";


/**
    @title Affitto. The contract allows for the registration of a user as either a student or a landlord. The student
    can try out the service while the landlord can register rooms. The student calls a function
    (contract instance) to enter into a contract with the landlord. You can withdraw but the other party takes your money.
    When both parties agree, the contract is successfully terminated and the landlord takes both's money (since the student's 
    deposit will serve as an actual deposit for the legal lease).
    
*/

contract Affitto {

    // emitted in case the fallback or receive functions get invoked
    event Log(string func, address sender, uint256 value, bytes data);

    /*  contract_instance contains all the information that needs to get track of when it comes to the contract instance
        contract_id: the contract's uinque id
        room_id: the room's unique id
        student: address of the student
        landlord: address of the landlord    
        student_paid: indicates whether the student has already paid the deposit
        landlord_paid: indicates whether the landlord has already paid the deposit
        amt_paid_student: amount paid by the student as a deposit. This amount is stored to make it easier when 
                          the contract transfers back the money to the parties
        amt_paid_landlord: amount paid by the landlord as a deposit. This amount is stored to make it easier when
                           the contract transfers back the money to the parties 
        concluded_student: indicates whether the student has already expressed the will to terminate the contract successfully
        concluded_landlord: indicates whether the landlord has already expressed the will to terminate the contract successfully 
        creation_time: timestamp of the moment the contract instance was created
        contract_phase: the phase the contract is currently in        
    */
    struct contract_instance {
        uint256 contract_id;
        uint256 room_id;
        address payable student;
        address payable landlord;
        bool student_paid;
        bool landlord_paid;
        uint256 amt_paid_student;
        uint256 amt_paid_landlord;
        bool concluded_student;
        bool concluded_landlord;
        uint256 creation_time;
        ContractPhase contract_phase;
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

    /*  role: specifies the role of the user, who can be either a student or a landlord
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
        Landlord,
        Student
    }

    /*  ContractPhase identifies the phase in which the contract instance can be
        INITIAL PHASE: it's the phase where one or both parties still have to pay their deposit. 
        This phase has a maximum duration which will be set at the application level. 
        This phase can be terminated in three ways:
            - The moment both parties pay for the deposit, the initial phase is concluded and the contract becomes STABLE
            - If one of the parties withdraws from the contract in this phase, then there are no penalties, if they or the other 
              party has already paid the money is given back to the respective parties (except for the revenue percentage 
              taken from the student's deposit, it they have already paid). Ther, the contract instance is deleted
            - If the maximum duration of this phase is reached. Then, the contract instance is deleted
        
        STABLE PHASE: it's the phase where both parties have paid their deposit and it's the phase in which the contract simply exist.
        This phase can be terminated in two ways:
            - If one party withdraws, all the money deposited in the contract, minus the percentage earned by the contract, is given to the other party
            - If both parties agree that the contract can end successfully, then all the money, minus the percentage earned by the contract, is given to the landlord
        
        HIBERNATED PHASE: When a party suspects the other of malevolent behavior, it can block the contract instance in an hibernated phase.
        This phase waits for the competent autorities to run the necessary checks on the reality of the situation and to decide which party 
        deserves the money deposited in the contract.
    */
    enum ContractPhase {
        Initial,
        Stable,
        Hibernated
    }

    // associates to each contract id the respective contract record
    mapping(uint256 => contract_instance) contract_record;
    uint256[] contract_record_keys;

    // associates to each address its respective user information
    mapping(address => user) user_info;  
    //address[] user_info_keys;

    // associates to each landlord an array that contains their rooms' id                 
    mapping(address => uint256[]) landlords_rooms;                
    //address[] landlords_rooms_keys;

    // associates to each room id the corresponding room information
    mapping(uint256 => room) rooms_record;
    //uint256[] rooms_record_keys; 
    
    // contains all the ids of the hibernated contracts and the address of the party that hibernated them
    mapping(uint256 => address) hibernated_contracts;

    // conversion rate from eur to wei
    uint256 conversion_rate = 586099570929370;  

    // global variable that is used to assign unique ids to contract instances                   
    uint256 num_contracts;      

    // deposit paid by the landlord as a guarantee of their good faith
    uint256 landlord_deposit; 

    uint256 time_limit_to_make_contract_stable;                                  

    constructor() {
        num_contracts = 1; // num_contracts start at 1 and not 0 because 0 is the default value for uint256 so we excluded it to avoid possible ambiguities
        landlord_deposit = 100;
        time_limit_to_make_contract_stable = 172800;  // it's the equivalent, in seconds, of 48 hours
    }

    /* @param ux, uy, c, z, hx, hy are the values outputted by the prover called on the user's private key

       The function allows the user to register either as a landlord or a student. The function prevents double registrations by checking the 'already init' field
       in the user struct. 
    
    */
    function register_landlord(uint256 ux, uint256 uy, uint256 c, uint256 z, uint256 hx, uint256 hy) public {
        // Doesn't allow double registrations
        require(!user_info[msg.sender].already_init, "User already registered");

        // call to the verifier to perform the account verification
        require(accountVerification.zkp_accountVer(ux, uy, c, z, hx, hy, msg.sender), "Account verification failed.");

        uint256[] memory array;
        user_info[msg.sender] = user({
            role: Role.Landlord, 
            contract_instance_record: array, 
            num_rooms: 0, 
            already_init: true
        });
        //user_info_keys.push(msg.sender);
        
    }

    /*  @param ux, uy, c, z, hx, hy are the values outputted by the prover called on the user's private key
        @param ux_stud, uy_stud, c_stud, z_stud, hx_stud, hy_stud are the values outputted by the 
        Prover called on the private information demonstrating the user's status as a student
    */
    function register_student(uint256 ux, uint256 uy, uint256 c, uint256 z, uint256 hx, uint256 hy, uint256 ux_stud, uint256 uy_stud, uint256 c_stud, uint256 z_stud, uint256 hx_stud, uint256 hy_stud) public {
        // Doesn't allow double registrations
        require(!user_info[msg.sender].already_init, "User already registered");

        // call to the verifier to perform the account verification
        require(accountVerification.zkp_accountVer(ux, uy, c, z, hx, hy, msg.sender), "Account verification failed.");

        // call to the verifier to perform the check on the user's status as a student
        // the application will have already performed a search on the presence of hx_stud and hy_stud 
        // in the public database, so the function only needs to check that the verifiers outputs the value 'true'
        require(zkp.Verifier(ux_stud, uy_stud, c_stud, z_stud, hx_stud, hy_stud), "Was not able to varify that the user is a student");
        
        uint256[] memory array;
        
        user_info[msg.sender] = user({
                role: Role.Student, 
                contract_instance_record: array, 
                num_rooms: 0, 
                already_init: true
            });
            //user_info_keys.push(msg.sender);
    }

    /*  @param rooms Array with the rooms ids
        @param deposits The deposit to pay for the corresponding room

        The landlord can register several rooms at once by providing the ids of the rooms, it adds the new room structs to the rooms_record_mapping
    */
    function register_rooms(uint256[] memory rooms, uint256[] memory deposits) public {
        // controlliamo che il chiamante sia un landlord
        require(user_info[msg.sender].role == Role.Landlord, "You are not a landlord therefore you're not allowed to register rooms");
        require(rooms.length == deposits.length, "Inconsistent information provided.");
        uint256 l = rooms.length;
        user_info[msg.sender].num_rooms += l; 

        for (uint256 i = 0; i < l; i++) {
            room memory new_room = room({id: rooms[i], owner: msg.sender, occupied: false, deposit: deposits[i]});
            landlords_rooms[msg.sender].push(rooms[i]);
            rooms_record[new_room.id] = new_room;
            //rooms_record_keys.push(new_room.id);
        }
        
    }   
    /*  @param landlord The address of the landlord
        @param room_id The id of the room
        @param timestamp time of the creation of the contract instance
        After performing some checks on the function caller and the landlord, the function creates a contract instance with the information provided.
        This function's version takes as a parameter also the room_id, in case the student has their heart already set on a specific room
    */
    // If the student has his heart already set on a specific room 
    function initialize(address payable landlord, uint256 room_id, uint256 timestamp) public {
        require(check_user_already_registered(msg.sender), "You are not an authorized user");
        require(check_user_already_registered(landlord), "landlord is not an authorized user");
        require(user_info[msg.sender].role == Role.Student, "You are not a student");
        require(user_info[landlord].role == Role.Landlord, "The address provided does not correspond to a landlord");

        address payable student = payable(msg.sender);
        
        // check that the student is not in a contract instance and that the room is not occupied
        require(check_if_already_in_contract(student, room_id) == false, "Student or room already in contract");
        
        // check that the landlord is the room's owner
        require(rooms_record[room_id].owner == landlord, "Inconsistency between room owner and landlord");

        // if neither the student and the room are already in a contract instance, the function proceeds with the creation of the contract instance
        uint256 new_id = num_contracts;
        num_contracts++;
        rooms_record[room_id].occupied = true;
        contract_instance memory instance = contract_instance({
            contract_id: new_id, 
            room_id: room_id,
            student: student, 
            landlord: landlord, 
            student_paid: false, 
            landlord_paid: false, 
            amt_paid_student: 0, 
            amt_paid_landlord: 0, 
            concluded_student: false, 
            concluded_landlord: false, 
            creation_time: timestamp,
            contract_phase: ContractPhase.Initial
        });

        contract_record[new_id] = instance;
        contract_record_keys.push(new_id);
        user_info[student].contract_instance_record.push(new_id);
        user_info[landlord].contract_instance_record.push(new_id);
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
        require(!instance.student_paid, "You already paid for this contract");
        uint256 paid_amount = msg.value;
        uint256 amt_to_pay = get_student_deposit_in_wei(instance.room_id);
        //console.log("Paid amount", paid_amount);
        //console.log("Amount to pay", amt_to_pay);
        require((amt_to_pay - 100000) <= paid_amount && paid_amount <= (amt_to_pay + 100000), "Wrong amount paid");
        
        if (instance.landlord_paid) {
            instance.contract_phase = ContractPhase.Stable;
        }

        instance.amt_paid_student = paid_amount;
        instance.student_paid = true;
        contract_record[contract_id] = instance;
        
        
    }

    /*  @param contract_id
        The function allows the student to pay the deposit for one of the rooms that are currently blocked in a contract instance
        The contract allows some tolerance on the amount received as the deposit
    */
    function landlord_pay_deposit(uint256 contract_id) public payable {
        uint256 amt_to_pay = get_landlord_deposit_in_wei();
        contract_instance memory instance = contract_record[contract_id];
        require(!instance.landlord_paid, "You already paid for this contract");
        Role role = user_info[msg.sender].role;
        require(role == Role.Landlord, "Data inconsistency"); // probabilmente inutile (già implicitamente incluso nel secondo require)
        require(msg.sender == instance.landlord, "Data inconsistency");
        uint256 paid_amount = msg.value;
        require((amt_to_pay - 100000) <= paid_amount && paid_amount <= (amt_to_pay + 100000), "Wrong amount paid"); 
        instance.amt_paid_landlord = paid_amount;
        instance.landlord_paid = true;

        if (instance.student_paid) {
            instance.contract_phase = ContractPhase.Stable;
        }
        contract_record[contract_id] = instance;    
    }

    /*  @param contract_id
        The function allows either party to withdraw from their contract
        The function behaves accordingly to the phase the contract is in
    */
    function withdraw_from_contract(uint256 contract_id) public {
        address receder = msg.sender;

        address other;

        contract_instance memory instance = contract_record[contract_id];
        require(instance.contract_phase != ContractPhase.Hibernated, "You can't withdraw from a hibernated contract");

        if (user_info[msg.sender].role == Role.Student) {
            // require also protects in case contract_id doesn't exist
            require(instance.student == msg.sender, "You tried to withdraw from a contract you are not a part of");
            other = contract_record[contract_id].landlord;
        }
        else {
            // require also protects in case contract_id doesn't exist
            require(instance.landlord == msg.sender, "You tried to withdraw from a contract you are not a part of");
            other = contract_record[contract_id].student;
        }
        uint256 room_id = instance.room_id;

        if (instance.contract_phase == ContractPhase.Initial) {
            if (instance.student_paid) {
                uint256 amt_to_give_back = instance.amt_paid_student * 10 / 11;
                instance.student.transfer(amt_to_give_back);
            }
            else if (instance.landlord_paid) {
                instance.landlord.transfer(instance.amt_paid_landlord);
            }
        }
        else if (instance.contract_phase == ContractPhase.Stable) {
            uint256 amt_to_give_back = instance.amt_paid_student * 10 / 11;
    
            payable(other).transfer(amt_to_give_back + instance.amt_paid_landlord);
        }
        delete_contract_instance(receder, other, contract_id, room_id); 
    }

    /*  @param contract_id
        function allows either party to end their contract successfully.
        It updates the contract instance to indicate that the sender has concluded the contract.
        If both parties have concluded the contract, it calls an internal to delete this contract instance
         and transfer any funds paid to the landlord
    */
    function end_contract_successfully(uint256 contract_id) public returns (bool) {
        contract_instance memory instance = contract_record[contract_id];
        require(instance.contract_phase == ContractPhase.Stable);
        /* require(instance.student_paid, "Student has yet to pay");
        require(instance.landlord_paid, "landlord has yet to pay"); */
        address student;
        address landlord;
        if (user_info[msg.sender].role == Role.Student) {
            student = msg.sender;
            require(instance.student == student, "You are trying to terminate a contract you are not a part of");
            instance.concluded_student = true;
            landlord = instance.landlord;
        }
        else if (user_info[msg.sender].role == Role.Landlord){
            landlord = msg.sender;
            require(instance.landlord == landlord, "You are trying to terminate a contract you are not a part of");
            instance.concluded_landlord = true;
            student = instance.student;
        }

        if (instance.concluded_landlord && instance.concluded_student) {
            uint256 amt_to_give_back = rooms_record[instance.room_id].deposit * conversion_rate;
            payable(landlord).transfer(amt_to_give_back);
            payable(landlord).transfer(instance.amt_paid_landlord);
            delete_contract_instance(student, landlord, contract_id, 0);
            return true;
        }
        else {
            contract_record[contract_id] = instance;
            return false;
        }
    }

    /*  @param contract id
        function to hibernate the contract if one party suspects malevolent behavior
     */
    function hibernate_contract(uint256 contract_id) public {
        contract_instance memory instance = contract_record[contract_id];
        require(instance.student == msg.sender || instance.landlord == msg.sender, "You are trying to hibernate a contract you are not a part of");
        require(instance.contract_phase == ContractPhase.Stable, "You can only hibernate a contract when it's considered stable");
        instance.contract_phase = ContractPhase.Hibernated;
        contract_record[contract_id] = instance;
        hibernated_contracts[contract_id] = msg.sender;
    }

    /*  @param contract_id
        this function allows the party who hibernated the contract to unlock it and restore its previous state of stable contract
        (pacific resolution)
     */
    function de_hibernate_contract(uint256 contract_id) public {
        require(hibernated_contracts[contract_id] == msg.sender, "You cannot unlock a contract instance if it wasn't you who hibernated it");
        delete(hibernated_contracts[contract_id]);
        contract_instance memory instance = contract_record[contract_id];
        instance.contract_phase = ContractPhase.Stable;
        contract_record[contract_id] = instance;
    }

    /*  @param contract_id
        allows one party in a hibernated contract to admit fault 
        All the money deposited in the contract (minus the 10% earned by the contract) are given to the other part and the contract instance is terminated
    */
    function admit_fault(uint256 contract_id) public {
        contract_instance memory instance = contract_record[contract_id];
        require(instance.student == msg.sender || instance.landlord == msg.sender, "You can't perform this action on a contract you are not a part of");
        require(instance.contract_phase == ContractPhase.Hibernated, "You can't perform this action on a contract that is not hibernated");
        address payable other;
        if (instance.student == msg.sender) {
            other = instance.landlord;
        }
        else {
            other = instance.student;
        }
        uint256 amt_to_give_back = instance.amt_paid_landlord + instance.amt_paid_student * 10 / 11;
        other.transfer(amt_to_give_back);
        delete(hibernated_contracts[contract_id]);
        delete_contract_instance(instance.student, instance.landlord, contract_id, instance.room_id);
    }

    /*  @param current_timestamp the current timestamp passed by the application; the time unit of the parameter is seconds
        The function iterates the mapping contract_record and checks, for each contract in the initial phase, if the time limit to make the contract stable has been reached
        if so, the contract instance gets deleted and the money potentially paid by one of the parties is given back (if the student gets refunded the contract keeps the 10% earning)
        the function returns an array with the contract ids of all the contracts instance that have been deleted
        Since the contract has no notion of time, the application will be in charge to periodically call this function
     */
    function check_unstable_contracts_validity(uint256 current_timestamp) public returns (uint256[] memory) {
        uint256[] memory expired_contracts = new uint256[](contract_record_keys.length); 
        for (uint256 i = 0; i < contract_record_keys.length; i++) {
            uint256 contract_id = contract_record_keys[i];
            contract_instance memory instance = contract_record[contract_id];
            if (instance.contract_phase == ContractPhase.Initial && current_timestamp >= (instance.creation_time + time_limit_to_make_contract_stable)) {
                expired_contracts[i] = contract_id;
                if (instance.student_paid) {
                    instance.student.transfer(instance.amt_paid_student * 10 / 11);
                }
                else if (instance.landlord_paid) {
                    instance.landlord.transfer(instance.amt_paid_landlord);
                }
                delete_contract_instance(instance.student, instance.landlord, contract_id, instance.room_id);
            }
        }
        //uint256[] memory actual_array = expired_contracts[0:actual_length];
        return expired_contracts; 
        // the array is with high probability partially "empty", but I can't slice it nor I can create it dynamically and use the push() method and I honestly feel like crying
        // It should be fine anyways because the default value should be zero and the contract ids start from 1, so there shouldn't be any ambiguity. 
        // The application will need to keep this into consideration though.
    }


/*     function get_user_info(address add) public view returns (bool, uint256[] memory, uint256, bool) {
        user memory u = user_info[add];
        bool role;
        if (u.role == Role.Landlord) {
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
        return landlords_rooms[a];
    }
     */

    function get_contract_info(uint256 contract_id) public view returns (uint256, uint256, bool, bool, uint256, uint256, bool, bool, address, address, ContractPhase) {
        contract_instance memory instance = contract_record[contract_id]; 
        return (contract_id, instance.room_id, instance.student_paid, instance.landlord_paid, instance.amt_paid_student, instance.amt_paid_landlord, instance.concluded_student, instance.concluded_landlord, instance.student, instance.landlord, instance.contract_phase);
    }

    // returns the deposit for the blocked room in wei with the 10% added as the contract's fee for the service
    function get_student_deposit_in_wei(uint256 room_id) public view returns (uint256) {
        uint256 deposit = rooms_record[room_id].deposit;
        uint256 net_amt_in_wei = deposit * conversion_rate;
        uint256 contract_gain = net_amt_in_wei / 10;
        return (net_amt_in_wei + contract_gain); 
    }

    function get_landlord_deposit_in_wei() public view returns (uint256) {
        return (landlord_deposit * conversion_rate);
    }

/*     function get_room_info(uint256 room_id) public view returns (uint256, address, bool, uint256) {
        room memory r = rooms_record[room_id];
        uint256 id = r.id;
        address owner = r.owner;
        bool occupied = r.occupied;
        uint256 deposit = r.deposit;
        return (id, owner, occupied, deposit);
    }
 */
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
        if (role == Role.Landlord) {
            //console.log("Role: ", true);
            //console.log("Instance landlord: ", instance.landlord);
            require(addr == instance.landlord, "Data inconsistency 1");
            return instance.landlord_paid;
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
        remove(contract_record_keys, contract_id);

        // mark the room as not occupied
        // if the room id is 0, then the function takes it as a default value to signal that the 
        // contract instance is being terminated successfully --> the  room keeps being marked as occupied
        if(room_id != 0) {
            rooms_record[room_id].occupied = false;
        }
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

    /* function remove(address[] storage array, address element) private {
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
    } */

    fallback() external payable {
        emit Log("fallback", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value, "");
    }
}

