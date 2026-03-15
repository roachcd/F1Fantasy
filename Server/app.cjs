require('dotenv').config();

const express = require('express');
const cors = require('cors');
const mysql = require('mysql');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const fs = require("fs");

const app = express();
app.use(cors());
app.use(express.json());

app.use(express.urlencoded({ extended: true }));
const SECRET_KEY = 'your_secret_key'; //TODO: Fix this

function getUserID(token){
    var id = -1
    jwt.verify(token, SECRET_KEY, (err, decoded) => {
      id = decoded.id
    });
    console.log("User Id is: ", id)
    return id
}

// Use a connection pool
const pool = mysql.createPool({
    connectionLimit: 10,
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: 'gridapps_betting',
    port: 3306
});

pool.on('error', (err) => {
  console.error('MySQL Pool Error:', err);
});

//Requests:
app.post('/test', async (req, res) => {
  console.log("test")
  res.json({ message: 'Test succeeded' });
});

// Register route (signup)
app.post('/register', async (req, res) => {
  console.log('register');

  const { email, password } = req.body;

  // Hash the password
  const hashedPassword = await bcrypt.hash(password, 10);

  const sql = 'INSERT INTO users (email, password) VALUES (?, ?)';
  pool.query(sql, [email, hashedPassword], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'User registered successfully!' });
  });
});

// Login route
//TODO: Make this get?
app.post('/login', (req, res) => {
  console.log("Login")
  const { email, password } = req.body;

  const sql = 'SELECT * FROM users WHERE email = ?';
  pool.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    if (results.length === 0) return res.status(401).json({ message: 'User not found' });

    const user = results[0];
    const email = user.email

    // Verify password
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(401).json({ message: 'Invalid password' });

    // Generate JWT token
    const token = jwt.sign({ id: user.id }, SECRET_KEY, { expiresIn: '7d' });
    res.json({ message: 'Login successful', token, email });
  });
});



const port = process.env.PORT || 3000;
app.listen(port);
console.log("Listening on " + port)

app.use((req, res) => {
  res.status(404).json({ message: "Not found" });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: "Server error" });
});