# Post-Incident Review

## Incident
The active Green deployment of KijaniKiosk Payments was intentionally stopped to simulate a production failure.

## Impact
Production traffic temporarily pointed to an unhealthy Green environment.

## Detection
The post-deployment monitor detected three consecutive failed health checks at five-second intervals.

## Automated Response
After the third failure, the rollback script automatically switched Nginx traffic from Green back to Blue.

## Timeline
- 21:37:17 UTC - Green fault introduced
- 21:37:21 UTC - First failure detected
- 21:37:26 UTC - Second failure detected
- 21:37:31 UTC - Third failure detected
- 21:37:31 UTC - Automatic rollback triggered
- 21:37:32 UTC - Nginx switched to Blue
- 21:37:35 UTC - Blue confirmed through production proxy

## Recovery Time
18 seconds from fault introduction to confirmed recovery.

## Root Cause
The incident was intentionally caused by stopping kk-api-green.service.

## What Worked
- Health monitoring detected the failure.
- The rollback target was determined automatically.
- Blue remained healthy during the incident.
- Nginx switched production traffic successfully.
- Recovery completed well within the 90-second target.

## Improvement
Future versions could add centralized logging, alerting, and deployment metrics for better observability.

## Outcome
PASS - automated rollback restored production successfully.
