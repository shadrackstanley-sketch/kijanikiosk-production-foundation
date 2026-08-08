# Week 8 Blue/Green Deployment Demo

## 1. Show Running Services

Commands:
systemctl is-active kk-api-blue.service
systemctl is-active kk-api-green.service

## 2. Show Versions

Blue: curl http://127.0.0.1:3000/health
Green: curl http://127.0.0.1:3001/health
Production: curl http://127.0.0.1:80/health

## 3. Switch to Green

sudo bash /opt/kijanikiosk/scripts/switch-env.sh green

Confirm:
curl http://127.0.0.1:80/health

## 4. Start Monitoring

sudo bash /opt/kijanikiosk/scripts/post-deploy-monitor.sh 60

## 5. Simulate Failure

sudo systemctl stop kk-api-green.service

## 6. Observe Automatic Rollback

The monitor detects three failures and automatically runs the rollback process.

## 7. Confirm Recovery

curl http://127.0.0.1:80/health

Expected version: v1.3.0

## 8. Evidence

Measured recovery time: 18 seconds
Target: under 90 seconds
Result: PASS
