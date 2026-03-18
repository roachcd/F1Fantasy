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

    $conn->query("
    INSERT INTO user_drivers (user_id, event_driver_id, league_id, event_id)
    SELECT b.user_id, b.event_driver_id, b.league_id, ed.event_id
    FROM bids b
    JOIN event_drivers ed
        ON ed.id = b.event_driver_id
    JOIN (
        SELECT b2.event_driver_id, MAX(b2.amount) AS max_amount
        FROM bids b2
        JOIN event_drivers ed2
            ON ed2.id = b2.event_driver_id
        WHERE ed2.event_id = $eventId
        GROUP BY b2.event_driver_id
    ) winners
        ON winners.event_driver_id = b.event_driver_id
    AND winners.max_amount = b.amount
    WHERE ed.event_id = $eventId
    AND NOT EXISTS (
        SELECT 1
        FROM user_drivers ud
        WHERE ud.event_driver_id = b.event_driver_id
        AND ud.event_id = ed.event_id
        AND ud.league_id = b.league_id
    );
    ");

    $conn->query("
    UPDATE events
    SET status = 1
    WHERE id = $eventId
    ");
}

$conn->close();