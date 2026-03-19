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
    INSERT INTO user_drivers (user_id, event_driver_id, league_id, event_id)
    SELECT w.user_id, w.event_driver_id, w.league_id, $eventId
    FROM (
        SELECT t1.user_id, t1.event_driver_id, t1.league_id, t1.total_amount
        FROM (
            SELECT
                b.user_id,
                b.event_driver_id,
                b.league_id,
                SUM(b.amount) AS total_amount,
                MAX(b.created_at) AS last_bid_at,
                MAX(b.id) AS last_bid_id
            FROM bids b
            JOIN event_drivers ed
                ON ed.id = b.event_driver_id
            WHERE ed.event_id = $eventId
            GROUP BY b.user_id, b.event_driver_id, b.league_id
        ) t1
        LEFT JOIN (
            SELECT
                b.user_id,
                b.event_driver_id,
                b.league_id,
                SUM(b.amount) AS total_amount,
                MAX(b.created_at) AS last_bid_at,
                MAX(b.id) AS last_bid_id
            FROM bids b
            JOIN event_drivers ed
                ON ed.id = b.event_driver_id
            WHERE ed.event_id = $eventId
            GROUP BY b.user_id, b.event_driver_id, b.league_id
        ) t2
        ON t1.event_driver_id = t2.event_driver_id
        AND t1.league_id = t2.league_id
        AND (
                t2.total_amount > t1.total_amount
                OR (
                    t2.total_amount = t1.total_amount
                    AND t2.last_bid_at < t1.last_bid_at
                )
                OR (
                    t2.total_amount = t1.total_amount
                    AND t2.last_bid_at = t1.last_bid_at
                    AND t2.last_bid_id < t1.last_bid_id
                )
            )
        WHERE t2.user_id IS NULL
    ) w
    ");

    $conn->query("
    UPDATE events
    SET status = 1
    WHERE id = $eventId
    ");
}

$conn->close();