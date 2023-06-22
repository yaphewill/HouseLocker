var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');

var indexRouter = require('./routes/index');
// var addRouter = require("./routes/add")
var sendRouter = require("./routes/send_money")
// var removeRouter = require("./routes/remove")
var userRouter = require('./routes/user');
var contractInitRouter = require('./routes/start_contract.js');
var roomsRouter = require('./routes/rooms');

// var localStorage = require('node-localstorage').LocalStorage;

var app = express();

// const {web3,Web3} = require("./web3_init")
// const {Hash} = require("./mongoose_init")

// view engine setup
app.set('views', path.join(__dirname, 'views'));
// app.set('views', path.join(__dirname, 'views/student'));
// app.set('views', path.join(__dirname, 'views/renter'));
app.set('view engine', 'ejs');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'build')));

app.use('/', indexRouter);
// app.use('/add', addRouter);
app.use('/send_money', sendRouter);
// app.use('/remove', removeRouter);
app.use('/user', userRouter);
app.use('/init', contractInitRouter);
app.use('/rooms', roomsRouter);



// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;

//TODO separate views of student and renter
