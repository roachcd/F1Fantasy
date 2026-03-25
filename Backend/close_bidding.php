<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$env = parse_ini_file(__DIR__ . '/.env');

$host = $env['DB_HOST'];
$user = $env['DB_USER'];
$password = $env['DB_PASS'];
$database = 'gridapps_f1b';

$conn = new mysqli($host, $user, $password, $database);
echo $conn->server_info;

if ($conn->connect_error) {
    die("DB connection failed");
}

$result = $conn->query("
SELECT id
FROM events
WHERE status = 2
AND bidding_closes_at <= NOW()
");

echo "matching events: " . $result->num_rows . PHP_EOL;

while ($event = $result->fetch_assoc()) {

    $eventId = $event['id'];

    // clear previous results
    $conn->query("
    DELETE FROM user_drivers
    WHERE event_id = $eventId
    ");

    $conn->query("
    INSERT INTO user_drivers (
        league_id,
        user_id,
        driver_id,
        event_driver_id,
        event_id
    )
    SELECT
        b.league_id,
        b.user_id,
        d.id AS driver_id,
        b.event_driver_id,
        $eventId AS event_id
    FROM bids b
    JOIN event_drivers ed
        ON ed.id = b.event_driver_id
    JOIN drivers d
        ON d.id = ed.driver_id
    JOIN (
        SELECT
            b1.event_driver_id,
            b1.league_id,
            MAX(b1.id) AS last_bid_id
        FROM bids b1
        JOIN event_drivers ed1
            ON ed1.id = b1.event_driver_id
        WHERE ed1.event_id = $eventId
        GROUP BY b1.event_driver_id, b1.league_id
    ) latest
        ON latest.last_bid_id = b.id
       AND latest.event_driver_id = b.event_driver_id
       AND latest.league_id = b.league_id
    WHERE ed.event_id = $eventId;
    ");

    $conn->query("
    UPDATE events
    SET status = 1
    WHERE id = $eventId
    ");
}

$conn->close();