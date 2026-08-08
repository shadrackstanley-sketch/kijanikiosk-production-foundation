# KijaniKiosk Week 9 Kubernetes Deployment

All application resources are deployed in the `kijani-project` namespace.

## Secret Recovery

The real `kk-payments-secrets` Secret is intentionally not committed to Git.

Secret name:

`kk-payments-secrets`

Expected keys:

- `DB_PASSWORD`
- `STRIPE_API_KEY`
- `JWT_SECRET`

If the cluster is deleted and recreated, obtain the real values from the team before deploying the application.

Create the Secret manually with:

kubectl create secret generic kk-payments-secrets --from-literal=DB_PASSWORD=REPLACE_ME --from-literal=STRIPE_API_KEY=REPLACE_ME --from-literal=JWT_SECRET=REPLACE_ME -n kijani-project

Never commit the real Secret values to Git.

## Deployment

After the namespace and Secret exist, apply the repository manifests with:

kubectl apply -f k8s/
