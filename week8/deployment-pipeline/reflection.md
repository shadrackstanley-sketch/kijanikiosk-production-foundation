# Week 8 Reflection

Week 8 focused on moving KijaniKiosk from basic CI/CD concepts into safer production deployment practices.

I implemented a blue/green deployment using two versions of the KijaniKiosk Payments service. Blue ran version v1.3.0 and Green ran version v1.4.0. Nginx was used to route production traffic between the two environments.

The most important part of this exercise was implementing automatic rollback. A post-deployment monitor checked the production health endpoint every five seconds. After three consecutive failures, the system automatically switched production back to the previous healthy environment.

During the controlled failure test, Green was deliberately stopped. The system detected the failure and restored Blue through the production proxy in 18 seconds, which was well below the 90-second rollback objective.

I also containerized the Payments service using Docker and deployed it to Kubernetes using Minikube. The Kubernetes Deployment used two replicas, readiness and liveness probes, and resource requests and limits.

The self-healing test demonstrated another important production concept. After one running pod was deliberately deleted, Kubernetes automatically created a replacement pod and restored the deployment to two healthy replicas.

This exercise showed me the difference between deployment safety and runtime resilience. Blue/green deployment gives a controlled way to release and roll back application versions, while Kubernetes continuously manages the health and desired state of application instances.

Overall, the Week 8 work demonstrated that reliable deployment is not only about successfully starting a new version. It also requires health validation, monitoring, rollback, redundancy, and automatic recovery when something fails.
