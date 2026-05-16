# Reflexió Individual — Pau Domingo Torrijos

---

Començar aquesta pràctica venint just de la primera ha estat un contrast. A la Práctica 1 ens vam acostumar a configurar un servidor a mà, cada paquet decidit, cada permís escrit explícitament. Aquí ens han demanat justament el contrari: oblidar-nos del servidor i pensar només en *abstraccions*. I aquesta inversió de perspectiva és el que crec que ens defineix l'aprenentatge de tot el quadrimestre.

## L'aspecte més desafiant

Per a mi, el repte més gros no ha estat aprendre una tecnologia concreta, sinó **canviar la manera de pensar entre setmanes**. Cada setmana introduïa una capa d'abstracció més: contenidors → composició → orquestració → codi sobre orquestració → pipeline sobre codi. I cada vegada que dominaves una capa, la següent et feia replantejar tot el que sabies. A la Setmana 8 estava orgullós del meu Dockerfile manual; a la Setmana 11, escriure manifests a mà ja semblava una pèrdua de temps i tot ho generàvem amb Terraform.

Concretament, la **Setmana 11 (CI/CD)** va ser la que més em va costar entendre. No el `ci.yml` en si, la sintaxi de GitHub Actions és bastant directa — sinó la **filosofia darrere de la separació CI/CD**. Per què no fer que el workflow apliqui directament els canvis al clúster? La resposta: "perquè GitHub Actions no pot tocar el teu Minikube local" — és tècnicament correcta però va ser una excusa per entendre el concepte més profund: **el codi no ha de tenir credencials de producció**. En entorns reals, el CI valida i genera artefactes; el CD el fa una eina separada amb permisos diferents, sovint un humà aprovant el rollout. Aquesta separació de responsabilitats em va costar interioritzar-la fins que la vaig viure.

## El que m'ha sorprès

 Durant anys havia sentit "Docker" com una paraula complicada associada a feines difícils, i en realitat és simplement: "empaqueta el teu programa amb el seu entorn perquè corri igual a tot arreu". El Dockerfile és bàsicament un guió de muntatge. Quan vaig veure el primer contenidor responent un `curl` a la meva màquina, vaig pensar: "ja està?". I sí, aquesta simplicitat resol uns problemes que abans destruïen projectes sencers.



## Què faria diferent si comencés de zero



**Hauria planificat les setmanes d'una manera més seriosa.** Vam treballar en mode "què toca aquesta setmana", quan en realitat cada setmana depèn fortament de l'anterior. Si la Setmana 8 deixa Dockerfiles mal optimitzats, ho pateixes a la Setmana 11 perquè el CI tarda més. Una planificació que mirés tres setmanes endavant ens hauria estalviat refactors.

**Hauria parlat més amb altres grups.** Quan vam quedar encallats amb Minikube i RAM, vam tardar un dia sencer a entendre el problema. Si haguéssim preguntat a algú més, segur que algú ja s'hi havia trobat. L'orgull tècnic és el principal enemic de la productivitat.

## Com ha canviat la meva manera d'entendre els sistemes

Abans d'aquest curs, un "servidor" per a mi era una caixa amb un sistema operatiu i programes corrent. Ara veig que aquesta visió és **gairebé obsoleta**. Avui un "servei" no viu en una màquina concreta — viu en una abstracció (un Deployment, una funció serverless, un job) que el clúster col·loca on convingui. La màquina és intercanviable, el contenidor és intercanviable, fins i tot el clúster sencer és intercanviable si el tens definit com a codi.

Aquesta filosofia es resumeix en una frase que vaig llegir durant la pràctica i no he deixat de pensar: **"Treats your servers like cattle, not pets"**. No els poses nom, no els cuides individualment, no et lamentes quan un mor,el reemplaces. Em va costar acceptar-ho perquè a la Práctica 1 vam *cuidar* el nostre servidor; vam posar-li hostnames, vam fer-li backups, l'estimàvem una mica. Aquesta pràctica m'ha fet entendre que aquesta era exactament l'actitud que el món modern intenta superar.

També he canviat la meva perspectiva sobre el **temps**. Abans pensava que "automatitzar" era una cosa que es feia "quan tens temps". Ara entenc que automatitzar **és** la feina. Tot el que fas dues vegades a mà és un script que no has escrit. Tot el script que no has escrit és un humà que algun dia s'equivocarà sota pressió.

## Què vull aprendre més endavant

Tinc llista llarga, però el que més m'interessa és:

- **Networking dins de Kubernetes a nivell real:** CNI plugins, NetworkPolicies seriosos, Ingress controllers, ports forwarding. La part 12 de l'enunciat la vam tocar superficialment i sé que és on hi ha molta xixa.

- **Llenguatges de configuració moderns:** CUE, Jsonnet, Cdk8s. Veure si hi ha algo millor que el YAML descontrolat.

## Conclusió

Sis setmanes han estat suficients per fer-me veure que **el que sabia abans no era infraestructura, era treball més manual**. La infraestructura moderna és enginyeria de programari aplicada a sistemes operatius: el mateix rigor, els mateixos patrons, les mateixes pràctiques (testing, versionat, revisió de codi, refactor). I, com tota enginyeria, no s'aprèn en sis setmanes — s'aprèn en una carrera sencera. Però sí que en aquestes sis setmanes he aprés a saber **on mirar**, **què preguntar** i **quin nom donar a les coses**. Per a un punt de partida, no està malament.

---

*Pau Domingo Torrijos — Práctica 2 GSX — Maig 2026*

---


