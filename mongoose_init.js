const { Int32 } = require('mongodb');
const mongoose = require('mongoose')

const hashSchema = new mongoose.Schema({
    hash: String,
})

const userchema = new mongoose.Schema({
    address:String,
    role:String,
})

const roomSchema = new mongoose.Schema({
    id:BigInt,
    address:String,
    fee:Number,
    beds:Number,
    exp_included:Boolean,
    renter: String,
    image:Number,
})

const Hash = mongoose.model('Hash', hashSchema);
const User = mongoose.model('User', userchema);
const Room = mongoose.model('Room', roomSchema);

mongoose.connect('mongodb+srv://davidepasetto1:ba14thg5OpUczEPP@houseblocker.llcycrt.mongodb.net/?retryWrites=true&w=majority',
{
    useNewUrlParser: true,
    useUnifiedTopology: true,

})
.then(()=>{
    console.log("success")
})
.catch(err=>{
    console.log("error:",err)
})

module.exports = {Hash,User,Room}