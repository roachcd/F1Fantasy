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
    database: 'gridapps_f1b',
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
    const id = user.id

    // Verify password
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(401).json({ message: 'Invalid password' });

    // Generate JWT token
    const token = jwt.sign({ id: user.id }, SECRET_KEY, { expiresIn: '7d' });
    res.json({ message: 'Login successful', token, email, id });
  });
});

app.get('/leagues', (req, res) => {
  console.log("Get Leagues");

  const auth = req.headers.authorization || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
  if (!token) return res.status(401).json({ message: "Missing token" });

  const userID = getUserID(token);

  const sql = 'select l.id, l.name, l.ownerId, l.season_id from user_leagues ul join leagues l on ul.league_id = l.id where user_id = ?;';
  pool.query(sql, [userID], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error" });
    res.json(result);
  });
});

app.get('/leagueManagers', (req, res) => {
  console.log('League Managers');
  const leagueId = req.query.leagueId;

  const sql = 'SELECT u.id, lm.username, lm.points FROM users u JOIN user_leagues lm ON lm.user_id = u.id WHERE lm.league_id = ?;';
  pool.query(sql, [leagueId], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
    res.json(result);
  });
});

app.get('/events', (req, res) => {
  const seasonId = req.query.seasonId;

  console.log('get events, season: ', seasonId);

  const sql = 'SELECT * FROM season_events JOIN events ON season_events.event_id = events.id WHERE season_id = ?;';
  pool.query(sql, [seasonId], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error" });
    res.json(result);
  });
});

app.get("/eventDrivers", (req, res) => {
  console.log("Event Drivers");

  const eventId = req.query.eventId;

  const sql = `
  SELECT 
    d.id as driver_id,
    d.name,
    ed.id AS event_driver_id,
    d.car_number,
    d.team,
    ed.position,
    ed.points,
    COALESCE(SUM(b.amount), 0) AS total_bids
FROM drivers d
JOIN event_drivers ed 
    ON d.id = ed.driver_id
LEFT JOIN bids b 
    ON b.event_driver_id = ed.id
WHERE ed.event_id = ?
GROUP BY 
    d.id,
    d.name,
    ed.id,
    d.car_number,
    d.team,
    ed.position,
    ed.points;`;
  pool.query(sql, [eventId], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
    res.json(result);
  });
})

app.get("/driverBids", (req, res) => {
  console.log("Driver Bids");

  const eventDriverId = req.query.eventDriverId;
  const leagueId = req.query.leagueId;

  const sql = 'SELECT b.id, ul.username AS manager_name, b.amount, b.created_at FROM bids b JOIN event_drivers ed ON b.event_driver_id = ed.id LEFT JOIN user_leagues ul ON ul.user_id = b.user_id AND ul.league_id = b.league_id WHERE b.event_driver_id = ? AND b.league_id = ?;';
  pool.query(sql, [eventDriverId, leagueId], (err, result) => {
    if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
    res.json(result);
  });
});

app.post("/placeBid", (req, res) => {
  console.log("Place Bid")
  const { token, event_driver_id, amount, league_id } = req.body;
  const userID = getUserID(token)
  const sql = 'INSERT INTO bids (user_id, event_driver_id, league_id, amount) VALUES (?, ?, ?, ?);';
  pool.query(sql, [userID, event_driver_id, league_id, amount], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Success!' });
  });
})

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