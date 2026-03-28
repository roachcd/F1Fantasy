/**
 * Backend API for the F1 Fantasy application.
 */

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

/**
 * Extracts the user ID from a JWT token.
 *
 * @param {string} token - The JWT token.
 * @returns {number} The decoded user ID, or `-1` if decoding fails.
 */
function getUserID(token) {
    var id = -1;
    jwt.verify(token, SECRET_KEY, (err, decoded) => {
        id = decoded.id;
    });
    console.log("User Id is: ", id);
    return id;
}

/**
 * MySQL connection pool used for all database queries.
 */
const pool = mysql.createPool({
    connectionLimit: 10,
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: 'gridapps_f1b',
    port: 3306
});

/**
 * Logs MySQL pool-level errors.
 */
pool.on('error', (err) => {
    console.error('MySQL Pool Error:', err);
});

// -----------------------------------------------------------------------------
// Health / Test
// -----------------------------------------------------------------------------

/**
 * Test endpoint used to confirm the server is running.
 *
 * @route POST /test
 * @returns {Object} JSON confirmation message.
 */
app.post('/test', async (req, res) => {
    console.log("test");
    res.json({ message: 'Test succeeded' });
});

// -----------------------------------------------------------------------------
// Authentication
// -----------------------------------------------------------------------------

/**
 * Registers a new user account.
 *
 * Hashes the provided password before storing the user in the database.
 *
 * @route POST /register
 * @param {string} req.body.email - User email.
 * @param {string} req.body.password - Plaintext password.
 * @returns {Object} Success or error response.
 */
app.post('/register', async (req, res) => {
    console.log('register');

    const { email, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    const sql = 'INSERT INTO users (email, password) VALUES (?, ?)';
    pool.query(sql, [email, hashedPassword], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'User registered successfully!' });
    });
});

/**
 * Authenticates a user and returns a JWT token.
 *
 * @route POST /login
 * @param {string} req.body.email - User email.
 * @param {string} req.body.password - Plaintext password.
 * @returns {Object} Login result including token, email, and user ID.
 */
app.post('/login', (req, res) => {
    console.log("Login");
    const { email, password } = req.body;

    const sql = 'SELECT * FROM users WHERE email = ?';
    pool.query(sql, [email], async (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length === 0) return res.status(401).json({ message: 'User not found' });

        const user = results[0];
        const email = user.email;
        const id = user.id;

        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) return res.status(401).json({ message: 'Invalid password' });

        const token = jwt.sign({ id: user.id }, SECRET_KEY, { expiresIn: '7d' });
        res.json({ message: 'Login successful', token, email, id });
    });
});

// -----------------------------------------------------------------------------
// League Data
// -----------------------------------------------------------------------------

/**
 * Returns all leagues associated with the authenticated user.
 *
 * Requires a bearer token in the `Authorization` header.
 *
 * @route GET /leagues
 * @returns {Array<Object>} League records for the current user.
 */
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

/**
 * Returns all managers in a league.
 *
 * @route GET /leagueManagers
 * @param {string} req.query.leagueId - League identifier.
 * @returns {Array<Object>} Managers and their points.
 */
app.get('/leagueManagers', (req, res) => {
    console.log('League Managers');
    const leagueId = req.query.leagueId;

    const sql = 'SELECT u.id, lm.username, lm.points FROM users u JOIN user_leagues lm ON lm.user_id = u.id WHERE lm.league_id = ?;';
    pool.query(sql, [leagueId], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
        res.json(result);
    });
});

/**
 * Finds a league by its invite or join code.
 *
 * @route GET /findLeague
 * @param {string} req.query.leagueCode - League code.
 * @returns {Array<Object>} Matching league records.
 */
app.get('/findLeague', (req, res) => {
    console.log("Find League");
    const league_code = req.query.leagueCode;

    const sql = 'select id, name, code from leagues where code = ?;';
    pool.query(sql, [league_code], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error" });
        res.json(result);
    });
});

/**
 * Adds the authenticated user to a league.
 *
 * @route POST /joinLeague
 * @param {number} req.body.league_id - League identifier.
 * @param {string} req.body.username - Username to use in the league.
 * @param {string} req.body.token - JWT token.
 * @returns {Object} Database result or error.
 */
app.post('/joinLeague', (req, res) => {
    console.log("Join League");
    const { league_id, username, token } = req.body;
    userId = getUserID(token);

    const sql = 'INSERT into user_leagues (user_id, league_id, username) VALUES (?, ?, ?)';
    pool.query(sql, [userId, league_id, username], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error" });
        res.json(result);
    });
});

// -----------------------------------------------------------------------------
// Events and Drivers
// -----------------------------------------------------------------------------

/**
 * Returns all events for a season.
 *
 * @route GET /events
 * @param {string} req.query.seasonId - Season identifier.
 * @returns {Array<Object>} Event records.
 */
app.get('/events', (req, res) => {
    const seasonId = req.query.seasonId;

    console.log('get events, season: ', seasonId);

    const sql = 'SELECT * FROM season_events JOIN events ON season_events.event_id = events.id WHERE season_id = ?;';
    pool.query(sql, [seasonId], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error" });
        res.json(result);
    });
});

/**
 * Returns all drivers for a specific event and league,
 * including total bid amounts per driver.
 *
 * @route GET /eventDrivers
 * @param {string} req.query.eventId - Event identifier.
 * @param {string} req.query.leagueId - League identifier.
 * @returns {Array<Object>} Driver and bidding summary data.
 */
app.get("/eventDrivers", (req, res) => {
    console.log("Event Drivers");

    const eventId = req.query.eventId;
    const league_id = req.query.leagueId;
    console.log(league_id);

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
      AND b.league_id = ?
    WHERE ed.event_id = ?
    GROUP BY 
        d.id,
        d.name,
        ed.id,
        d.car_number,
        d.team,
        ed.position,
        ed.points;`;

    pool.query(sql, [league_id, eventId], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
        res.json(result);
    });
});

/**
 * Returns all bids for a given event driver in a league.
 *
 * @route GET /driverBids
 * @param {string} req.query.eventDriverId - Event-driver identifier.
 * @param {string} req.query.leagueId - League identifier.
 * @returns {Array<Object>} Bid history records.
 */
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

/**
 * Places a bid for a driver in a league event.
 *
 * @route POST /placeBid
 * @param {string} req.body.token - JWT token.
 * @param {number} req.body.event_driver_id - Event-driver identifier.
 * @param {number} req.body.amount - Bid amount.
 * @param {number} req.body.league_id - League identifier.
 * @param {number} req.body.fee - Fee amount applied to the bid.
 * @returns {Object} Success or error response.
 */
app.post("/placeBid", (req, res) => {
    console.log("Place Bid");
    const { token, event_driver_id, amount, league_id, fee } = req.body;
    const userID = getUserID(token);

    const sql = 'INSERT INTO bids (user_id, event_driver_id, league_id, amount, fee) VALUES (?, ?, ?, ?, ?);';
    pool.query(sql, [userID, event_driver_id, league_id, amount, fee], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Success!' });
    });
});

/**
 * Returns the authenticated user's league-specific profile data.
 *
 * @route GET /thisLeagueUser
 * @param {string} req.query.leagueId - League identifier.
 * @returns {Array<Object>} Matching user-league records.
 */
app.get("/thisLeagueUser", (req, res) => {
    console.log("Get thisLeagueUser");
    const league_id = req.query.leagueId;

    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
    if (!token) return res.status(401).json({ message: "Missing token" });

    const userID = getUserID(token);

    const sql = 'select user_id, username, money from user_leagues where league_id = ? and user_id = ?;';
    pool.query(sql, [league_id, userID], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error" });
        res.json(result);
    });
});

/**
 * Returns the official lineup for a user in an event.
 *
 * Uses the authenticated user if a token is present, otherwise falls back
 * to the `userId` query parameter.
 *
 * @route GET /eventLineup
 * @param {string} req.query.eventId - Event identifier.
 * @param {string} req.query.leagueId - League identifier.
 * @param {string} [req.query.userId] - Optional user identifier.
 * @returns {Array<Object>} Driver lineup records.
 */
app.get('/eventLineup', (req, res) => {
    console.log("Event Lineup");

    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
    const eventId = req.query.eventId;
    const leagueId = req.query.leagueId;

    let userId = -1;
    if (token) {
        userId = getUserID(token);
    } else {
        userId = req.query.userId;
    }

    console.log(userId, leagueId, eventId);

    const sql = "SELECT d.id AS driver_id, ed.id AS event_driver_id, d.name, d.car_number, d.team, ed.position, ed.points, -1 AS total_bids FROM user_drivers ud JOIN event_drivers ed ON ed.id = ud.event_driver_id JOIN drivers d ON d.id = ed.driver_id WHERE ud.league_id = ? AND ud.user_id = ? AND ud.event_id = ?;";
    pool.query(sql, [leagueId, userId, eventId], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
        res.json(result);
    });
});

/**
 * Returns the latest unofficial lineup based on most recent bids
 * for the selected event and user.
 *
 * @route GET /unofficialEventLineup
 * @param {string} req.query.eventId - Event identifier.
 * @param {string} req.query.leagueId - League identifier.
 * @param {string} [req.query.userId] - Optional user identifier.
 * @returns {Array<Object>} Bid-derived lineup data.
 */
app.get('/unofficialEventLineup', (req, res) => {
    console.log("Unofficial Event Lineup");

    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
    const eventId = req.query.eventId;
    const leagueId = req.query.leagueId;

    let userId = -1;
    if (token) {
        userId = getUserID(token);
    } else {
        userId = req.query.userId;
    }

    const sql = `
    SELECT
        d.id AS driver_id,
        b.event_driver_id,
        d.name,
        ed.position,
        ed.points,
        d.car_number,
        d.team,
        b.amount,
        b.created_at,
        latest.total_amount AS total_bids
    FROM bids b
    JOIN event_drivers ed
        ON ed.id = b.event_driver_id
    JOIN drivers d
        ON d.id = ed.driver_id
    JOIN (
        SELECT
            b1.event_driver_id,
            b1.league_id,
            MAX(b1.id) AS last_bid_id,
            SUM(b1.amount) AS total_amount
        FROM bids b1
        JOIN event_drivers ed1
            ON ed1.id = b1.event_driver_id
        WHERE ed1.event_id = ?
        GROUP BY b1.event_driver_id, b1.league_id
    ) latest
        ON latest.last_bid_id = b.id
       AND latest.event_driver_id = b.event_driver_id
       AND latest.league_id = b.league_id
    WHERE ed.event_id = ?
      AND b.league_id = ?
      AND b.user_id = ?;
    `;

    pool.query(sql, [eventId, eventId, leagueId, userId], (err, result) => {
        if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
        res.json(result);
    });
});

// -----------------------------------------------------------------------------
// Admin
// -----------------------------------------------------------------------------

/**
 * Returns all drivers in the system.
 *
 * @route GET /drivers
 * @returns {Array<Object>} Driver records.
 */
app.get("/drivers", (req, res) => {
    console.log("All Drivers");

    const sql = "select id as driver_id, name, car_number, team, -1 as cost, -1 as points from drivers;";
    pool.query(sql, (err, result) => {
        if (err) return res.status(500).json({ message: "DB error: Error is " + err.sqlMessage });
        res.json(result);
    });
});

/**
 * Returns all leagues in the system.
 *
 * @route GET /allLeagues
 * @returns {Array<Object>} League records.
 */
app.get('/allLeagues', (req, res) => {
    console.log("All Leagues");
    const sql = 'SELECT * FROM leagues';
    pool.query(sql, (err, result) => {
        if (err) return res.status(500).json({ message: "DB error" });
        res.json(result);
    });
});

// -----------------------------------------------------------------------------
// Server Setup
// -----------------------------------------------------------------------------

/**
 * Server port.
 */
const port = process.env.PORT || 3000;

/**
 * Starts the Express server.
 */
app.listen(port);
console.log("Listening on " + port);

/**
 * Fallback handler for unknown routes.
 */
app.use((req, res) => {
    res.status(404).json({ message: "Not found" });
});

/**
 * Global error handler.
 */
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ message: "Server error" });
});