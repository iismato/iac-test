### Cert manager

Cert manager je nástroj v Kubernetes clustri, ktorý automatizuje správu TLS certifikátov. Je to kľúčová súčasť infraštruktúry, ktorá poskytuje automatické HTTPS zabezpečenie pre aplikácie bežiace v clustri. Jeho hlavné úlohy sú:
1. Automatická správa certifikátov
  - Automaticky žiada, obnovuje a spravuje TLS/SSL certifikáty
  - Podporuje rôznych poskytovateľov certifikátov (tzv. issuers), najčastejšie Let's Encrypt
2. Integrácia s Kubernetes
  - Používa Custom Resource Definitions (CRDs) na definovanie certifikátov
  - Automaticky vytvára Kubernetes secrets obsahujúce certifikáty
  - Spolupracuje s Ingress kontrolérmi (v tomto prípade s Traefikom)

### Inštalácia

```bash
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
kubectl apply -f ./cluster-issuer.yaml
```

Pri inštalácii:
- sa cert-manager inštaluje do vlastného namespace
- inštalujú sa potrebné CRDs
- aplikuje sa cluster-issuer konfig

### Cluster issuer

- cluster-issuer definuje globálnu konfiguráciu pre získavanie certifikátov
- ako poskytovcateľa definuje Let's Encrypt production server
- je nakonfigurovaný HTTP01 challenge cez Traefik ingress controller