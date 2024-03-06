import { eratostene } from './controllers/eratostene.js';
import { pigreco } from './controllers/pigreco.js';
import express  from 'express';
import mustacheExpress from 'mustache-express';
import passport from 'passport';
import LocalStrategy from 'passport-local';
import session from 'express-session';
import mysql from 'mysql2';
import crypto from 'crypto';

import dotenv from 'dotenv';
dotenv.config();

/*Express Config*/
var app = express();
app.set('views','./views');
app.set('view engine', 'mustache');
app.engine('mustache', mustacheExpress());
app.use(express.static('assets'));
app.use(express.urlencoded({ extended: false }));


/*Passport*/
passport.use(new LocalStrategy(function verify(username, password, cb) { 

   const connection = mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB
   });
   connection.connect();

   connection.query('SELECT * FROM Users WHERE username = ?',username,function (error, results, fields) {
      if(error) throw error;
      if(results.length==0) return cb(null,false,{ message: 'Credenziali non valide' })
      
      let candidate = crypto.createHash('sha512').update(password + results[0].Salt).digest('hex').toUpperCase();
      if( results[0].Password != candidate) return cb(null,false,{ message: 'Credenziali non valide' })

      return cb(null,{user:username})
   });
}));

app.use(session({
   secret: process.env.SESSION_SECRET,
   resave: false,
   saveUninitialized: false
}));
app.use(passport.authenticate('session'));
app.use(passport.initialize());
 
passport.serializeUser(function(user, cb) {
   cb(null, { username: user.user });
});
 
passport.deserializeUser(function(user, cb) {
   return cb(null, user);
});

function isAuthenticated(req, res, next) {
   if (req.isAuthenticated()) {
     return next();
   }
   res.redirect('/login');
}

/*Login*/
app.get('/login', function(req, res, next) {
   res.render('login');
 });

app.post('/login', passport.authenticate('local', {
   successRedirect: '/',
   failureRedirect: '/login',
   failureMessage:true
 }));

 app.get('/logout',isAuthenticated, function(req, res, next) {
   req.logout(function(err) {
     if (err) { return next(err); }
     res.redirect('/');
   });
 });

/*Home Page*/
app.get('/', isAuthenticated, function (req, res) {
   res.render('index',{ 
        pageTitle: 'Laboratorio di piattaforme e metodologie cloud - AA 2023-24', is_home: true
    });
})

/*Numeri Primi*/
app.get('/numeriprimi', isAuthenticated, function (req, res) {
   res.render('index',{
      pageTitle: 'Calcolo numeri primi', is_numeriprimi: true
   })
})

app.post('/numeriprimi', isAuthenticated, function (req, res) {
   let numero = parseInt(req.body.numero);
   if( isNaN(numero)) 
      res.render('index',{ 
         pageTitle: 'Calcolo numeri primi', is_numeriprimi: true, soloPrimi:req.body.soloPrimi,
         error:'Inserire un numero valido'
      });
   else
      res.render('index',{ 
         pageTitle: 'Calcolo numeri primi', is_numeriprimi: true, numero:numero, soloPrimi:req.body.soloPrimi,
         result:eratostene(numero,req.body.soloPrimi ? true : false)
      });
 })

 /*PiGreco*/
app.get('/pigreco', isAuthenticated, function (req, res) {
   res.render('index',{
      pageTitle: 'Calcolo pi greco', is_pigreco: true
   })
})

app.post('/pigreco', isAuthenticated, function (req, res) {
   let numero = parseInt(req.body.numero);
   if( isNaN(numero)) 
      res.render('index',{ 
         pageTitle: 'Calcolo numeri primi', is_pigreco: true,
         error:'Inserire un numero valido'
      });
   else
      res.render('index',{ 
         pageTitle: 'Calcolo numeri primi', is_pigreco: true, numero:numero,
         result:pigreco(numero)
      });
})

/*Info*/
app.get('/info', isAuthenticated, function (req, res) {
   res.render('index',{
      pageTitle: 'Info', is_info: true
   })
})

/*404*/
app.use(function(req, res, next) {
   res.status(404).send('Sorry cant find that!');
 });

/*Avvio Server*/
var server = app.listen(process.env.PORT || 8080, function () {
   var host = server.address().address
   var port = server.address().port
})