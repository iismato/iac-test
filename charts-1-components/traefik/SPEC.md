### Traefik

Traefik v rámci Kubernetes clustra slúži ako Ingress Controller a load balancer. Má nasledovné úlohy:

1. Správa vstupného bodu (Ingress)
  - Funguje ako vstupná brána pre všetku HTTP/HTTPS komunikáciu do clustra
  - Smeruje požiadavky na správne služby podľa definovaných pravidiel
2. SSL/TLS Terminácia
  - Automaticky zabezpečuje HTTPS komunikáciu
  - Integruje sa s cert-managerom pre automatickú správu certifikátov
  - Používa Let's Encrypt ako poskytovateľa certifikátov
  ```
  # values.yaml
  - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
  - "--certificatesresolvers.letsencrypt.acme.email=m.nemcek@investinslovakia.eu"
  - "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
  ```
3. Automatické presmerovanie HTTP na HTTPS
  - Všetka HTTP komunikácia (port 80) je automaticky presmerovaná na HTTPS (port 443)
  ```
  # values.yaml
  - "--entrypoints.web.address=:80"
  - "--entrypoints.websecure.address=:443"
  - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
  - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
  - "--entrypoints.web.http.redirections.entryPoint.permanent=true"
  ```
4. Load Balancing
  - Funguje ako LoadBalancer služba v Kubernetes
  ```
  # values.yaml
  service:
  type: LoadBalancer
  ```
5. Perzistencia
  - Uchováva konfiguráciu a certifikáty v perzistentnom úložisku
  ```
  # values.yaml
  persistence:
    enabled: true
    accessMode: ReadWriteOnce
    size: 128Mi
    path: /data
  ```
6. Bezpečnosť - Beží s obmedzenými právami a bezpečnostnými nastaveniami
  - securityContext
    ```
    # values.yaml
    securityContext:
      capabilities:
        drop: [ALL]
    ```
    - odstráni všetky Linux capabilities z kontajnera, čo zabezpečí, že kontajner nemá žiadne špeciálne privilégiá
    - je to dôležité, pretože znižuje potenciálny dopad v prípade kompromitácie kontajnera
  - readOnlyRootFilesystem
    ```
    # values.yaml
    readOnlyRootFilesystem: true
    ```
    - nastaví root filesystem kontajnera ako read-only, čo zabraňuje modifikácií súborového systému v run-time a tým znižuje riziko infekcií a neoprávnených zmien
  - používateľské práva
    ```
    # values.yaml
    runAsGroup: 65532
    ```
    runAsNonRoot: true
    runAsUser: 65532
    - `runAsNonRoot: true` - zabezpečí, že kontajner nikdy nebeží ako root používateľ
    - `runAsUser: 65532` - špecifikuje UID používateľa (65532 je štandardný non-root používateľ)
    - `runAsGroup: 65532` - špecifikuje GID skupiny
    - toto je kritické pre bezpečnosť, pretože obmedzuje privilégiá procesu
  - podSecurityContext
    ```
    # values.yaml
    podSecurityContext:
      fsGroup: 65532
    ```
    - nastavuje skupinové ID pre prístup k súborom, čo zabezpečí, že všetky procesy v pode majú správne oprávnenia

  Prečo je táto konfigurácia dôležitá:
  1. Princíp najmenších privilégií - kontajner beží len s minimálnymi potrebnými oprávneniami
  2. Ochrana pred útokmi - znižuje attack surface a možnosti útočníka v prípade kompromitácie
  3. Súlad s best practices - sleduje odporúčané bezpečnostné praktiky pre Kubernetes
  4. Auditovateľnosť - jasne definované bezpečnostné nastavenia uľahčujú audit
  5. Predvídateľnosť - kontajner má konzistentné správanie z bezpečnostného hľadiska