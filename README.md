# IAC k8s setup pre api

## Prerekvizity

### k8s cluster
- vytvor k8s cluster v digital ocean
- potom si skopíruj [clusterId] a connectni sa na cluster via doctl cli `doctl kubernetes cluster kubeconfig save [clusterId]`

### container registry
- vytvor container registry and preklikaj sa cez getting started kroky
- v kroku 2. sa lokalne pripoji na register via `doctl registry login`
- v kroku 3. akonáhle je k8s cluster provisioned, naintegruj ho na container registry; toto vieš spraviť aj v k8s clusters settings

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

## argo-1-bootstrap
```
cd ./argo-1-bootstrap/argocd
kubectl create namespace argocd
```

1.
```
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build
helm upgrade --install argo . --namespace argocd
```
alebo 2.
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
spustenie argocd UI
```
kubectl -n argocd get secret argocd-initial-admin-secret \
          -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward service/argo-argocd-server -n argocd 8080:443
```

### inštalácia argocd-image-updater

  Autentifikacia Digital Ocean Registry:
  1. Prihlásenie do DO a získanie Docker credentials:
  ```bash
  # Inicializácia DO CLI
  doctl auth init --access-token YOUR_ACCESS_TOKEN

  # Získanie Docker config
  doctl registry docker-config
  # Výstup: {"auths":{"registry.digitalocean.com":{"auth":"AUTH_TOKEN"}}}
  ```

  2. Vytvorenie Kubernetes secret-u:
  ```bash
  # Zakódovanie Docker config do base64
  echo -n '{
    "auths": {
      "registry.digitalocean.com": {
        "auth": "AUTH_TOKEN"
      }
    }
  }' | base64

  # Vytvorenie secret YAML
  apiVersion: v1
  kind: Secret
  metadata:
    name: do-registry-secret
    namespace: argocd
  type: kubernetes.io/dockerconfigjson
  data:
    .dockerconfigjson: BASE64_ENCODED_AUTH_TOKEN
  ```

  3. Konfigurácia ArgoCD Image Updater ConfigMap:
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: argocd-image-updater-config
    namespace: argocd
  data:
    registries.conf: |
      registries:
      - name: registry.digitalocean.com
        prefix: registry.digitalocean.com
        api_url: https://registry.digitalocean.com
        credentials: secret:argocd/do-registry-secret#.dockerconfigjson
        defaultplatform: linux/amd64
    log.level: debug
  ```

  4. Konfigurácia ApplicationSet s anotáciami:
  ```yaml
  metadata:
    annotations:
      argocd-image-updater.argoproj.io/image-list: image=registry.digitalocean.com/ktest1/dir:argoapp-latest
      argocd-image-updater.argoproj.io/image.update-strategy: digest
      argocd-image-updater.argoproj.io/image.allow-tags: regexp:argoapp-latest
      argocd-image-updater.argoproj.io/image.platform: linux/amd64
  ```

  5. Aplikovanie konfigurácií:
  ```bash
  # Aplikovanie secret-u
  kubectl apply -f do-registry-secret.yaml -n argocd 

  # Aplikovanie ConfigMap
  kubectl apply -f image-updater-configmap.yaml -n argocd

  # Aplikovanie ApplicationSet
  kubectl apply -f application.yaml -n argocd

  # Reštart Image Updater
  kubectl rollout restart deployment argocd-image-updater -n argocd
  ```

  6. Overenie:
  ```bash
  # Kontrola logov
  kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater

  # Test prístupu k registry
  curl -u "api:REGISTRY_TOKEN" \
      "https://registry.digitalocean.com/v2/ktest1/dir/tags/list"
  ```

  Dôležité poznámky:
  - Všetky credentials musia byť správne base64 enkódované
  - Secret musí byť typu `kubernetes.io/dockerconfigjson`
  - ConfigMap musí obsahovať správnu cestu k secret-u
  - Anotácie v ApplicationSet musia presne zodpovedať štruktúre registry/repository

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
