# Week 8 Deployment Strategy Comparison

## Blue/Green Deployment

The blue/green approach used two live application environments:

- Blue: v1.3.0 on port 3000
- Green: v1.4.0 on port 3001
- Nginx routed production traffic on port 80

The main benefit was fast rollback. When Green failed, the monitoring script detected three consecutive health failures and automatically switched traffic back to Blue.

Measured rollback time:

18 seconds

Result:

PASS - recovery completed in under the 90-second target.

## Kubernetes Deployment

The containerized KijaniKiosk Payments service was deployed to Minikube using Kubernetes.

The deployment used:

- Docker image: kijanikiosk-payments:v1.4.0
- 2 replicas
- Readiness probe
- Liveness probe
- CPU and memory requests and limits
- NodePort service on port 30080

Kubernetes also demonstrated self-healing. One pod was deliberately deleted and the Deployment automatically created a replacement pod while maintaining the desired replica count.

## Comparison

Blue/green deployment is useful when a new release must be introduced with minimal risk and a quick rollback path.

Kubernetes provides broader application orchestration features such as replica management, self-healing, health probes, resource controls, and service discovery.

In this Week 8 implementation, blue/green deployment handled controlled release switching and rollback, while Kubernetes handled container orchestration and automatic recovery of failed application instances.

## Conclusion

Both approaches improve deployment reliability, but they solve different problems.

Blue/green deployment reduces release risk.

Kubernetes improves runtime resilience and operational automation.

Using both concepts together provides a stronger production deployment strategy.
