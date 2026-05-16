# Reflexió Individual — Adrià Cabré Acer

---

Han estat sis setmanes intenses en què hem passat de tenir un servidor gestionat manualment a una infraestructura completament containeritzada, orquestrada i automatitzada via codi. Mirant enrere, la transformació és bastant gran: la Práctica 1 ens va ensenyar a *operar* un servidor; la Práctica 2 ens ha ensenyat a *no haver d'operar-lo*. I aquest canvi de paradigma és, probablement, el que més m'ha sorprès.

## L'aspecte més desafiant

Sense cap mena de dubte, la Setmana 10 (Kubernetes) ha estat la més difícil per a mi. Docker l'havia tocat alguna vegada per curiositat i Docker Compose se sent com una extensió natural, defineixes serveis, els esborres, parlen entre ells. Però Kubernetes és **un altre món**: deployments, services, pods, replicasets, configmaps... cada concepte sembla simple aïllat, però la primera vegada que un pod es queda en `Pending` sense motiu aparent i `kubectl describe` retorna mig kilòmetre de YAML, et sents perdut.

El que finalment em va fer "clic" va ser entendre que Kubernetes és **declaratiu**: tu li dius com vols que sigui el món, no què ha de fer. Aquest canvi mental — de "executa això" a "fes que això sigui veritat sempre", és el que distingeix scripting d'infraestructura moderna. Quan vam matar un pod manualment al `verify_week10.sh` i vam veure que en cinc segons en naixia un altre sense que ningú fes res, va ser la primera vegada que vaig sentir que entenia per què aquesta tecnologia s'usa tant avui en dia.

## El que m'ha sorprès

Esperava que Docker fos més màgic del que és. La realitat és que un contenidor **no és una màquina virtual**: és simplement un procés del kernel amb namespaces aïllats. Descobrir-ho mirant amb `ps aux` al host i veure els processos del contenidor allà. Tot el que pensava que era "una caixa amb dintre un Linux" en realitat és "un procés amb una vista molt limitada del sistema operatiu".

Una altra cosa que no m'esperava: **la importància dels detalls aparentment menors**. Una imatge `nginx:alpine` ocupa 20 MB; `nginx:latest` (Debian) ocupa 140 MB. En un contenidor sembla irrellevant, qui mira els 120 MB de diferència? Però quan tens 200 instàncies del contenidor en producció i un CI que tira 50 builds al dia, aquesta diferència es converteix en **gigabytes de transferència**, **temps de build multiplicat per 10** i **costos reals de cloud**. Aprendre a pensar en aquesta escala és el que diferencia un script casolà d'una infraestructura professional.

També m'ha sorprès la cura amb què cal pensar la **seguretat per defecte**. Que un contenidor corri com a `root` no era cap problema fins que algú em va explicar què passa si un atacant aconsegueix escapar del contenidor. De cop, els petits detalls com `USER node` al Dockerfile o redirigir el PID de nginx a `/tmp` no són paranòia, són seguretat bàsica.

## Què faria diferent si comencés de zero

**Començaria documentant des del dia u.** Vam deixar el README per a les últimes setmanes i quan vam haver de tornar enrere per explicar decisions de la Setmana 8, vam haver de rellegir-nos els nostres propis Dockerfiles per recordar per què havíem triat alpine, per què el port 8080 i no 80, per què multistage. Si haguéssim escrit dues línies de justificació al moment, ens hauríem estalviat hores.

**Hauria investigat més sobre alternatives.** Vam triar Terraform per recomanació de l'enunciat, però mai vam aturar-nos a comparar-lo seriosament amb Ansible o Pulumi. No dic que la decisió fos dolenta — segueixo creient que Terraform és l'opció correcta per a aquest projecte —, però la decisió va ser feta per defecte, no per anàlisi. Un enginyer madur tria les eines amb criteri, no per inèrcia.

**Hauria fet el CI/CD més aviat.** El vam deixar per a la Setmana 11 i, és el que més ens hauria estalviat temps a les setmanes anteriors. Cada vegada que tocàvem el Dockerfile, fèiem `docker build`, `docker tag`, `docker push` a mà. Si haguéssim configurat el pipeline a la Setmana 8, tota la fricció dels passos repetitius hauria desaparegut.

## Com ha canviat la meva manera d'entendre el DevOps

Abans d'aquesta pràctica, "DevOps" era una etiqueta que les empreses posen a feines on combines programar i administrar servidors. Ara entenc que DevOps no és un rol, és **un model de treball**: assumir que la infraestructura és codi com qualsevol altre, que ha de ser versionada, revisada, testejada i automatitzada. Si has de tocar un servidor a mà, alguna cosa no està bé.

També he interioritzat el concepte de **infraestructura immutable**: no actualitzes un servidor, el reemplaces. Sembla una manera dràstica de fer les coses fins que entens que és l'única manera fiable d'evitar la deriva de configuracions. Cada contenidor que despleguem és exactament el mateix; si trobem un bug, el corregim a la imatge, la rebuildem amb un SHA nou i fem rollout. Mai modifiquem un contenidor que ja corre.

## Què vull aprendre més endavant

La llista és llarga. Em queden ganes de continuar amb:

- **Kubernetes a nivell de producció real:** Helm charts, operators, service mesh (Istio, Linkerd). Minikube és un parc infantil; vull veure què passa amb un clúster gestionat (EKS, GKE) amb desenes de nodes.
- **Seguretat de contenidors:** image scanning, signing amb cosign, supply chain security, runtime security amb Falco. La superfície d'atac d'una infraestructura cloud-native és enorme i poc intuïtiva.

## Conclusió

Sis setmanes és poc temps per dominar Docker, Compose, Kubernetes, Terraform i CI/CD, i no els domino. Però he aprés a navegar-los, a saber **quan i per què** usar cada eina, i sobretot a saber **què demanar al Google o IA** quan em quedi encallat. Si la Práctica 1 em va ensenyar a sobreviure davant d'una terminal, la Práctica 2 m'ha ensenyat a no haver de tornar-hi mai més. I aquesta, potser, és la lliçó més valuosa: l'objectiu de l'enginyeria d'infraestructura no és tocar més servidors, és tocar-ne menys.

---

*Adrià Cabré Acer — Práctica 2 GSX — Maig 2026*

---
