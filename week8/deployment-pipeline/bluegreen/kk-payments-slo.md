# KijaniKiosk Payments Service SLO

## Availability Target
The KijaniKiosk Payments service should remain available for at least 99.9% of the deployment period.

## Health Requirement
The /health endpoint must return HTTP 200 and the expected production version.

## Deployment Requirement
A new release must first be validated in the inactive environment before production traffic is switched.

## Rollback Objective
If the new production environment fails health checks, automated rollback must restore the previous healthy version in less than 90 seconds.

## Monitoring Policy
Post-deployment monitoring runs every 5 seconds.
Three consecutive health failures trigger automatic rollback.

## Week 8 Validation Result
- Green version: v1.4.0
- Rollback target: Blue v1.3.0
- Fault introduced: 2026-08-08 21:37:17 UTC
- Blue restored through production proxy: 2026-08-08 21:37:35 UTC
- Total recovery time: 18 seconds
- Result: PASS
