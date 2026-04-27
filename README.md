# 🟢 GreenDevCorp - Manual d'Infraestructura i Administració

### Projecte: Foundational Server Administration (GSX)
**Administradors:** Pau Domingo Torrijos i Adrià Cabré Acer

---

##  Índex de Continguts
1. [Arquitectura i Configuració Inicial](#arquitectura)
2. [Accés Remot i Seguretat (Setmana 1)](#setmana1)
3. [Serveis, Timers i Observabilitat (Setmana 2)](#setmana2)
4. [Control de Recursos i Processos (Setmana 3)](#setmana3)
5. [Col·laboració, Permisos i PAM (Setmana 4)](#setmana4)
6. [Emmagatzematge i Backups (Setmana 5)](#setmana5)
7. [Guia de Troubleshooting (Resolució de Problemes)](#troubleshooting)
8. [Guia d'Onboarding per a Nous Membres](#onboarding)
9. [Protocol de Recuperació de Desastres](#recuperacio)

---
























## <a name="arquitectura"></a>1. Arquitectura i Configuració Inicial
La infraestructura es basa en un servidor **Debian 13 (Trixie)** virtualitzat. 

Per garantir la col·laboració professional, hem centralitzat la gestió a `/opt/admin`.

* **Estructura de Directoris pels Administradors:**
    * `scripts/`: Lògica d'automatització i manteniment.
    * `configs/`: Fitxers de configuració, unitats de systemd i plantilles.
    * `logs/`: Registres de l'activitat dels scripts i serveis de backup.
    * `backups/`: Còpies locals (ignorat per Git via `.gitignore`).

En quan als altres usuaris que no son Administradors disponen del següent arbre de directoris a `/home/`.

* **Estructura de Directoris  i Fitxers pels altres usuaris COMPARTITS (`home/greendevcorp/`):**
    * `done.log/`: Llista de tasques pendents on nomès pot editar el cap de projectes.
    * `shared/`: Directori compartit per usuaris del mateix grup.
 
A banda cada usuari treballador té un directori individual amb accés restringit a ell mateix (`home/devX/` on "X" és el número de usuari):

Pel que fa a les backups es guarden dins del directori `/var/backups/backups_gsx/`



---

## <a name="setmana1"></a> 2. Accés Remot i Seguretat (Setmana 1)
* **SSH Segur:** S'ha prohibit el login directe de `root`. Utilitzem **claus SSH** per eliminar la dependència de contrasenyes.
* **Privilegis Segurs:** L'administrador opera com a usuari `gsx` i escala privilegis via `sudo`.
* **Scripts Clau:**
    * `setup_packages.sh`: Instal·la el programari essencial.
    * `verify_setup.sh`: Script de diagnòstic per validar la instal·lació.

---

## <a name="setmana2"></a> 3. Serveis, Timers i Observabilitat (Setmana 2)

Per garantir que la infraestructura de GreenDevCorp funcioni de manera autònoma i fiable, hem dissenyat una arquitectura basada en `systemd` que cobreix l'alta disponibilitat l'automatització i la monitorització de l'estat del sistema.

### A. Alta Disponibilitat i Resiliència (Nginx)
No ens podem permetre que una fallada puntual deixi el servidor web inactiu.
* **Auto-recuperació (Drop-in Override):** En lloc de modificar el fitxer del servei original de Nginx (el qual es podria sobreescriure en una actualització del paquet), hem creat un directori override (`/etc/systemd/system/nginx.service.d/override.conf`).
* **Configuració:** Hem afegit les directives `Restart=on-failure` i `RestartSec=5s`. Això garanteix que, si el procés mor inesperadament, `systemd` el reiniciarà automàticament al cap de 5 segons, reduint el temps de caiguda (downtime) a pràcticament zero sense intervenció manual.

### B. Automatització de Tasques (systemd Timers)
Hem substituït l'ús clàssic de `cron` per `systemd timers`, ja que ofereixen una observabilitat molt superior i un control d'execució precís.
* **Estratègia de Backups Escalonats:** Hem configurat tres parells d'unitats `.timer` i `.service` per executar l'script unificat `backup_data.sh`:
  * **24h:** Execució diària (`OnCalendar=daily`) per a `/opt/admin/logs`
  * **72h:** Execució cada 3 dies (`OnCalendar=*-*-1/3 00:00:00`). En aquest cas farem backup de `/home/dev1` corresponent al directori del developer "jefe".
  * **7D:** Execució setmanal (`OnCalendar=weekly`). En aquest cas aquest backup amb timer hem decidit que s'encarregui de fer copies de `/home/gsx/Documents` on hi hauran documents d'informació del sistema en un futur.
* **Persistència contra apagades (`Persistent=true`):** Una decisió de disseny clau en els nostres timers és l'activació d'aquesta directiva. Si el servidor està aturat durant l'hora programada per al backup, `systemd` recordarà l'esdeveniment perdut i executarà la tasca immediatament en engegar la màquina.
* **Aïllament de Recursos (cgroups):** Els serveis de backup corren com a `root` (`Type=oneshot`) però estan fortament limitats perquè el procés de compressió (`tar`) no saturi els recursos d'altres serveis. Apliquem un límit de **30% de CPU** (`CPUQuota=30%`) i un màxim de **200 MB de RAM** (`MemoryMax=200M`).

### C. Observabilitat i Gestió de Logs
Un sistema no és fiable si no podem saber què ha fallat quan hi ha un error ("You can't fix what you can't see").
* **Prevenció de saturació de disc (Logrotate):** Amb el temps, els logs poden omplir la partició principal. Per evitar-ho, hem creat `/etc/systemd/journald.conf.d/99-limits.conf` establint un topall d'espai al disc de **100MB** (`SystemMaxUse=100M`) i un temps de retenció màxim de **3 mesos** (`MaxRetentionSec=3month`).
* **Eina de Diagnòstic Ràpid (`check_logs.sh`):** Hem desenvolupat un script interactiu (`/opt/admin/scripts/check_logs.sh`) reservat per a administradors (`sudo`). Aquesta eina mostra les últimes incidències del servei web Nginx, l'estat dels backups automàtics i el percentatge d'espai que estan ocupant actualment els registres del journal.

---

## <a name="setmana3"></a> 4. Control de Recursos i Processos (Setmana 3)

Amb el creixement de la startup, els desenvolupadors i els serveis en segon pla comencen a competir pels recursos limitats del servidor (1 CPU, 2GB RAM). Per evitar que processos pesats ofeguin l'entorn de treball i afectin la disponibilitat de Nginx, hem dissenyat una estratègia integral d'inspecció, aïllament i control de cicle de vida.

### A. Diagnòstic Avançat i Inspecció del Kernel
Davant del clàssic problema "el servidor va lent", hem deixat enrere la simple dependència de `top` per desenvolupar eines de diagnòstic automatitzades que llegeixen directament del pseudo-sistema de fitxers `/proc`:
* **Visió Global (`diagnose_processes.sh`):** Analitza la càrrega del sistema (`/proc/loadavg`) i l'estat de la memòria (`/proc/meminfo`), oferint una llista filtrada amb els 5 processos que més CPU i RAM consumeixen. També genera un arbre de dependències amb `pstree` per entendre qui ha llançat cada procés (parent-child relationship).
* **Deep-Dive de Processos (`diagnose_specific_process.sh`):** Si sospitem d'un servei concret (ex. `systemd` o `nginx`), aquest script extreu mètriques vitals llegint `/proc/$PID/status`. Monitoritzem els **fils d'execució (Threads)** i els **canvis de context voluntaris (voluntary_ctxt_switches)**, una mètrica clau per saber si un procés està esperant constantment operacions d'I/O (disc/xarxa) o si realment està col·lapsant la CPU.

### B. Cicle de Vida, Senyals i "Graceful Shutdown"
Un enginyer d'operacions no pot simplement "matar" processos a la brava i arriscar-se a corrompre dades. Hem implementat un `workload_simulator.sh` per dominar el control de tasques:
* **Gestió de Senyals (Traps):** L'script intercepta senyals POSIX mitjançant la comanda `trap`. Quan rep un `SIGTERM (15)` (petició de tancament) o un `SIGINT (Ctrl+C)`, executa una rutina de neteja que mata el procés fill generador de càrrega (`yes`) de forma segura abans de sortir. Com a últim recurs en casos d'un procés zombi irrecuperable, la nostra guia defineix l'ús de `SIGKILL (9)`.
* **Control d'Estats i Prioritats:** Tal com mostra el simulador, hem documentat com alterar l'estat dels processos sense destruir-los: pausar temporalment (`SIGSTOP`), reprendre execucions (`SIGCONT`), i reduir la prioritat de consum d'un procés pesat modificant el seu valor *nice* a 10 (`renice -n 10`).

### C. Aïllament de Serveis (cgroups v2)
Limitar un procés manualment amb `ulimit` no és suficient per a serveis del sistema. Hem confiat en els Control Groups v2 implementats directament a `systemd`:
* **Workload Simulator Contingut:** L'hem integrat com a servei (`workload-simulator.service`) amb `CPUQuota=25%` i `MemoryMax=100M`. El Kernel de Linux talla l'accés a recursos tan bon punt assoleix el topall, evitant caigudes per falta de memòria (OOM).
* **Backups sense impacte:** Hem aplicat aquesta mateixa filosofia de forma proactiva als nostres serveis de backup (`backup-gsx-24h.service`, etc.). Les operacions de compressió `tar` estan estrictament confinades a un **30% d'un nucli de CPU** i **200 MB de RAM**. Això garanteix que, encara que el backup s'executi mentre els desenvolupadors treballen, no notaran lentitud.

### D. Seguretat i Límits PAM contra Abusos
Per protegir el sistema d'errors de programació dels usuaris (o atacs intencionats), hem blindat els límits de sessió a través dels Pluggable Authentication Modules (PAM) editant `/etc/security/limits.d/gsx-limits.conf`:
* **Protecció contra Fork-Bombs (`nproc`):** Hem limitat la quantitat de processos simultanis a 300 (límit `soft` que genera avís) i 400 (límit `hard` absolut). Si un script entra en un bucle infinit de creació de processos, el sistema aturarà l'usuari abans que el servidor es bloquegi.
* **Control de Descriptors de Fitxer (`nofile`):** Hem fixat un límit `soft` de 1024 i un `hard` de 4096 arxius oberts simultàniament. Això prevé atacs d'esgotament de recursos (resource exhaustion) on una aplicació monopolitzaria tots els descriptors del kernel.

### E. Runbook: Troubleshooting de Rendiment
Si un desenvolupador reporta que "el servidor va lent", els passos procedimentats de l'equip de sistemes són:
1. Executar `sudo ./scripts/diagnose_processes.sh` per validar la càrrega global.
2. Si un procés específic monopolitza la CPU sense justificació, reduir la seva prioritat amb `renice -n 10 <PID>` de forma temporal.
3. Si el procés s'ha penjat (ex. un script bloquejat en I/O), enviar senyal de tancament segur: `kill -15 <PID>`.
4. Si després de 10 segons no ha finalitzat l'execució netament (no respon a `SIGTERM`), forçar l'eliminació amb `kill -9 <PID>` com a mètode d'emergència.

---

## <a name="setmana4"></a> 5. Col·laboració, Permisos i PAM (Setmana 4)

Amb la incorporació de l'equip de desenvolupament (4 programadors inicials), el sistema deixa de ser monopost per convertir-se en un entorn col·laboratiu. El repte principal és permetre que l'equip treballi conjuntament a `/home/greendevcorp` sense que es puguin esborrar la feina els uns als altres o comprometre l'estabilitat del servidor. Hem aplicat rigorosament el **Principi de Mínim Privilegi (PoLP)**.

### A. Gestió d'Usuaris i Entorn Estandarditzat
Hem automatitzat l'onboarding de nous usuaris per garantir un entorn de treball predictible i segur:
* **Estructura de Grups:** S'ha creat el grup principal `greendevcorp` que agrupa els desenvolupadors (`dev1` a `dev4`), separant-los completament del grup d'administració (`sudo`/`gsx`).
* **Entorn Compartit (Shell Config):** Per evitar configurar manualment el `.bashrc` de cada usuari, hem creat una regla global a `/etc/profile.d/greendevcorp_env.sh`. Quan qualsevol membre de l'equip fa login, hereta automàticament els àlies del projecte (com `work` per anar ràpid al directori compartit) i se li afegeix la carpeta `/home/greendevcorp/bin` al seu `PATH` per poder executar binaris d'equip.

### B. Permisos Especials (Octals Avançats)
Els permisos UNIX estàndard (755/644) es queden curts per a una carpeta compartida real. Per solucionar-ho, hem configurat `/home/greendevcorp/shared` amb el permís octal **3750**, que inclou:
* **SetGID (Bit 2):** Qualsevol fitxer o carpeta nova creada dins de `shared` heretarà automàticament el grup `greendevcorp` en lloc del grup privat de l'usuari creador. Això soluciona el clàssic problema de "no puc editar el fitxer que acaba de crear el meu company".
* **Sticky Bit (Bit 1):** Tot i ser un directori col·laboratiu, activem el *Sticky Bit* perquè **només el propietari** d'un fitxer (o el root) pugui esborrar-lo o reanomenar-lo. Prevé esborrats accidentals o malintencionats entre companys de l'equip.
* **Fitxers Crítics (`done.log`):** Hem establert que el log de tasques (`done.log`) tingui permisos `644` i propietari `dev1`. Tothom pot llegir les tasques, però només el cap de projecte (`dev1`) les pot donar per tancades.

### C. Advanced Access Control (POSIX ACLs)
Els permisos UNIX per grup eren massa amplis, ja que donaven el mateix nivell a tots els integrants de l'equip. Per aconseguir granularitat fina, hem implementat **Llistes de Control d'Accés (ACLs)** via `setfacl`:
* **Rols diferenciats:** `dev1` i `dev2` (desenvolupadors sènior) tenen drets totals d'escriptura (`rwx`), mentre que `dev3` i `dev4` (júniors/contractistes) només tenen permisos de lectura i execució (`r-x`) sobre la carpeta compartida.
* **ACLs per Defecte (`-d`):** Hem aplicat les regles de forma hereditària. Qualsevol subcarpeta o fitxer creat en el futur adoptarà automàticament aquest esquema d'ACLs asimètric.
* Això es verifica contínuament amb el nostre script d'auditoria `verify_users_setup.sh`, que simula un "hack" intentant escriure amb l'usuari `dev3` i validant que el Kernel retorna `Permission denied`.

### D. Contenció i Límits d'Usuari (PAM)
En un entorn multiusuari, l'aïllament a nivell de sistema operatiu és vital. Hem blindat l'equip `@greendevcorp` modificant el mòdul PAM a `/etc/security/limits.d/greendevcorp-team.conf`:
* **Control d'Espai d'Adreçament (`as`):** Hem limitat la memòria virtual màxima que pot demanar un programador a aprox. **512 MB** (`524288 KB`) per evitar fugues de memòria (Memory Leaks) en el seu codi.
* **Límits `nproc` i `nofile`:** Restringim els processos (`soft 100`, `hard 200`) i els fitxers oberts simultanis (`soft 1024`, `hard 2048`) per immunitzar el servidor contra scripts fora de control (ex. *fork-bombs*) que poguessin aturar l'execució d'Nginx.

### E. Auditories i Offboarding (Gestió de Cicle de Vida)
Què passa si un desenvolupador marxa de la startup? L'esborrat no pot ser només manual.
* Hem desenvolupat un script d'offboarding blindat (`delete_user.sh`) exclusiu per a l'administrador. 
* Aquest script s'encarrega d'interrompre qualsevol sessió de `systemd/logind` activa (`loginctl terminate-user`), matar processos penjats en background (`pkill -9`) i esborrar l'usuari netament. Tot seguit, reorganitza els IDs de la resta de l'equip de forma automàtica (escalafó) per mantenir la coherència de l'entorn de treball.

---

## <a name="setmana5"></a> 6. Emmagatzematge i Backups (Setmana 5)

L'objectiu d'aquesta setmana ha estat dissenyar i implementar una estratègia de còpies de seguretat robusta per a GreenDevCorp que garanteixi la persistència de les dades de l'equip de desenvolupament (`/home/greendevcorp`) i permeti una ràpida recuperació en cas de desastre, complint amb la regla d'or 3-2-1.

### A. Storage Layout (Arquitectura de Discs)
Hem separat físicament el sistema operatiu de les dades de backup per evitar que una fallada del disc principal arrossegui les còpies de seguretat.
* **Disc Principal (`/dev/sda` - 20 GB):** Conté el sistema operatiu, aplicacions, logs i l'entorn col·laboratiu de l'equip (`/home/greendevcorp`).
* **Disc Secundari (`/dev/sdb` - 10 GB):** Emmagatzematge dedicat exclusivament a backups. 
  * **Format:** `ext4` (robust i amb suport natiu per a atributs, permisos i ACLs).
  * **Persistència:** S'ha automatitzat el muntatge a `/mnt/backup_drive` mitjançant `/etc/fstab` utilitzant l'**UUID** del disc. Això garanteix que el sistema arrenqui correctament encara que canviï l'ordre del maquinari.

### B. Capacity Planning (Planificació de Capacitat)
El dimensionament del nou disc de 10 GB s'ha calculat preveient el creixement de la startup a 10 desenvolupadors:
* Com que implementem backups **incrementals** (`rsync`), només emmagatzemem els canvis diaris (deltas), reduint dràsticament l'ús d'espai.
* Estimem un volum de canvis d'uns 50 MB diaris. Amb una retenció de 30 dies, ocuparem aproximadament 1.5 GB. El disc de 10 GB ens dona un marge de creixement superior al 500%.

### C. Backup Strategy (Estratègia 3-2-1)
Hem dissenyat una estratègia **Híbrida**, combinant els punts forts dels backups de la Week 1 i els de la Week 5:
* **Backups Incrementals (Diàriament amb `rsync`):** Sincronitzen el codi de `/home/greendevcorp` cap al disc `/dev/sdb`. Són extremadament ràpids i eficients, ideals per recuperar l'estat exacte del dia anterior si un desenvolupador esborra un fitxer per error. Retenció: 30 dies.
* **Backups Complets (Setmanalment amb `tar`):** El sistema heretat de la Week 1 empaqueta infraestructures i altres carpetes vitals en un `.tar.gz`. Ideal per a restauracions cataclísmiques i arxivament profund. Retenció: 3 mesos.

**Compliment de la Regla 3-2-1:**
* **3 Còpies:** Dades de producció, Backup complet (`tar`) i Backup incremental (`rsync`).
* **2 Suports Diferents:** Disc principal (`sda`) i disc secundari aïllat (`sdb`).
* **1 Offsite:** *(Preparat per a la Part E mitjançant exportació NFS cap a un servidor remot).*

### D. Automated Backup (Implementació)
Per automatitzar l'estratègia incremental, hem creat una arquitectura basada en `systemd` garantint fiabilitat i observabilitat:
1. **Script (`backup_incremental.sh`):** Utilitza `rsync -aq --delete` per crear una còpia mirall exacta conservant propietaris, grups i permisos especials (SetGID/Sticky Bit/ACLs) configurats a la Week 4.
2. **Servei (`backup-incremental.service`):** Tipus `oneshot`, executat com a `root`. Incorpora límits de recursos (cgroups: `CPUQuota=40%`, `MemoryMax=300M`) per garantir que el procés de backup no saturi el rendiment del servidor Nginx.
3. **Programador (`backup-incremental.timer`):** S'executa cada dia a les 02:00 AM (`OnCalendar=*-*-* 02:00:00`). L'opció `Persistent=true` assegura que si el servidor està apagat a aquella hora, el backup es farà just en engegar-lo.

---

## <a name="troubleshooting"></a>7. Guia de Troubleshooting (Resolució de Problemes)
Aquesta guia permet diagnosticar fallades seguint una metodologia sistemàtica.

| Problema | Símptoma | Acció de Resolució |
| :--- | :--- | :--- |
| **Servidor lent** | Càrrega alta a `/proc/loadavg`. | Executar `sudo ./scripts/diagnose_processes.sh` per trobar el procés consumidor. |
| **Nginx no respon** | Servei inactiu o falla el port 80. | Comprovar logs amb `journalctl -u nginx`. Reiniciar manualment amb `systemctl restart nginx`. |
| **Backup fallit** | Falta l'arxiu `.tar.gz` o log d'error. | Verificar el timer amb `systemctl status backup-gsx-24h.timer` i revisar `/opt/admin/logs/backup.log`. |
| **Accés denegat** | Usuari no pot escriure a `/shared`. | Verificar permisos amb `getfacl /home/greendevcorp/shared`. Comprovar si l'usuari és al grup `greendevcorp`. |
| **Procés zombi** | Processos bloquejats a `pstree`. | Identificar PID i enviar `SIGTERM (15)`. Si no respon, usar `SIGKILL (9)` com a últim recurs. |



---

## <a name="onboarding"></a> 8. Guia d'Onboarding per a Nous Membres
Passos per integrar un nou enginyer d'operacions o desenvolupador al sistema.

### A. Creació del Compte
1. **Crear usuari:** `sudo useradd -m -s /bin/bash devX`.
2. **Assignar grup:** `sudo usermod -aG greendevcorp devX`.
3. **Establir límits:** Verificar que els límits a `/etc/security/limits.d/greendevcorp-team.conf` s'apliquen correctament.

### B. Configuració de l'Entorn
L'entorn es configura automàticament gràcies a `/etc/profile.d/greendevcorp_env.sh`. El nou membre disposarà de:
* Accés directe al directori de treball via àlies `work`.
* Binaris compartits al `PATH` (`/home/greendevcorp/bin`).
* Comandes de diagnòstic ràpid com `ll`.

### C. Accés al Repositori
1. L'usuari ha de generar una clau SSH: `ssh-keygen -t ed25519`.
2. Afegir la clau pública al fitxer `authorized_keys` del servidor.
3. Clonar aquest repositori a la seva carpeta local per col·laborar en els scripts.

### D. Offboarding (Baixa d'un Membre)
Si un desenvolupador abandona la startup, el procés d'esborrat s'ha de fer de manera neta i segura per no deixar processos zombis ni trencar la jerarquia de l'equip.
1. **Executar script d'Offboarding:** `sudo bash /opt/admin/scripts/delete_user.sh <numero_dev>` (ex: `sudo bash delete_user.sh 2`).
2. **Què fa l'script per sota?**
   * Tanca qualsevol sessió de `systemd/logind` activa (`loginctl terminate-user`).
   * Força l'aturada de processos en background (`pkill -9`).
   * Esborra l'usuari i la seva carpeta home (`userdel -r`).
   * Reorganitza automàticament la resta de desenvolupadors (promociona `dev3` a `dev2`, etc.) per mantenir la coherència de l'entorn de treball i traspassa la propietat del `done.log` si escau.

---

## <a name="recuperacio"></a> 9. Protocol de Recuperació de Desastres (Runbook)

Aquest manual descriu els procediments d'actuació en cas de pèrdua de dades a GreenDevCorp. Totes les operacions de restauració de la Week 5 han estat provades i validades mitjançant l'script automatitzat `test_restore.sh`.

*Nota de seguretat: A causa de les restriccions d'ACLs implementades a la Week 4, totes les tasques de recuperació a `/home/greendevcorp` han de ser executades per un administrador utilitzant `sudo` per evitar errors de "Permission denied".*

### Escenari 1: Recuperació Granular (Un fitxer esborrat per error)
Aquest és l'escenari més comú. El codi font original resideix a `/home/greendevcorp/shared`.
1. Accedir al servidor com a administrador (`gsx` amb privilegis `sudo`).
2. Anar al disc de còpies de seguretat: `cd /mnt/backup_drive/incrementals/greendevcorp/shared/`
3. Cercar el fitxer o carpeta esborrada en aquest directori.
4. Restaurar-lo manualment a la seva ubicació original preservant els atributs (`-a`):
   `sudo rsync -a <nom_del_fitxer> /home/greendevcorp/shared/`
5. Verificar amb el desenvolupador afectat que el fitxer és accessible.

### Escenari 2: Pèrdua Total de l'Entorn de Desenvolupament
Si tot el directori `/home/greendevcorp` s'ha corromput o esborrat.
1. Com a `root`, aturar els serveis que puguin escriure a disc (ex. Nginx) si fos necessari.
2. Volcar la còpia mirall de la nit anterior directament sobre producció. L'ús del paràmetre `-a` és crític perquè restaurarà automàticament els permisos, propietaris i les POSIX ACLs de la Week 4:
   `sudo rsync -a /mnt/backup_drive/incrementals/greendevcorp/ /home/greendevcorp/`
3. Reiniciar els serveis i verificar l'accés de l'equip.

### Escenari 3: Corrupció del Directori Administratiu (Infraestructura com a Codi)
En cas de fallada total, corrupció o esborrat de `/opt/admin` (Week 1):
1. Executar l'script de recuperació d'emergència: `sudo bash /opt/admin/scripts/recovery_setup.sh` (si encara és accessible a la memòria, en cas contrari tornar a clonar via Git).
2. L'script netejarà el directori i forçarà el retorn al **commit de seguretat b36fbb4**.
3. L'script s'encarregarà de reaplicar automàticament els permisos de col·laboració (`root:sudo` a 775/770) perquè l'equip de sistemes pugui continuar operant sense problemes.
