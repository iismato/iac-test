# IAC k8s setup pre api

## Prerekvizity

### k8s cluster
- vytvor k8s cluster v digital ocean
- potom si skopíruj [clusterId] a connectni sa na cluster via doctl cli `doctl kubernetes cluster kubeconfig save [clusterId]`

### container registry
- vytvor container registry and preklikaj sa cez getting started kroky
- v kroku 2. sa lokalne pripoji na register via `doctl registry login`
- v kroku 3., akonáhle je k8s cluster provisioned, naintegruj ho na container registry; toto vieš spraviť aj v k8s clusters settings

## charts-1-bootstrap
```
cd ./charts-1-bootstrap/argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build
helm upgrade --install argo . -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret \
          -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward service/argocd-server -n argocd 8080:443
```

### inštalácia traefik-u
```
cd ./charts-1-components/traefik
helm repo add traefik https://traefik.github.io/charts
helm dependency build
helm upgrade --install traefik .
```

### inštalácia cert-manager-a
```
cd ./charts-1-components/cert-manager
helm repo add jetstack https://charts.jetstack.io
helm dependency build
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
kubectl apply -f ./cluster-issuer.yaml
```

### inštalácia argocd-image-updater

Vytvorenie secret pre Digital Ocean Registry
```
kubectl create secret docker-registry digitalocean-registry-secret \
--docker-server=registry.digitalocean.com \
--docker-username=<your-api-token> \
--docker-password=<your-api-token> \
--namespace argocd
```

Inštalácia image updater
```
cd ./charts-1-components/argocd-image-updater
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build
helm upgrade --install argocd-image-updater . -n argocd
```

### presmerovanie subdomén pre api & admin appky na external IP traefiku
Po nainštalovaní traefiku počkaj, než sa ti vygeneruje jeho externá IP adresa. Zvyčajne to trvá pár minút. Získaš ju príkazom `kubectl get service traefik`. Potom v DNS nastaveniach subdomén vytvor A záznam a nasmeruj ho na túto IP.

## charts-2-apps setup

### api inštalácia
In ./charts-2-apps/api folder, add values-test.yaml or values-prod.yaml with overriden values and then run
`sh deploy.sh test` or `sh deploy.sh production`
