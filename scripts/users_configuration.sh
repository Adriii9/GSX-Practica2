#!/bin/bash
# ==============================================================================
# SCRIPT: Crear i configurar USUARIS
# DESCRIPCIÓ: Configuració d'usuaris, ACLs, entorn i límits de recursos.
# ==============================================================================

# 0. Instal·lar l'eina de llistes de control d'accés (ACL) si no hi és
apt-get update -qq && apt-get install -y acl

# ==============================================================================
# PART A: USUARIS I GRUPS 
# ==============================================================================
echo "[+] Creant grup compartit i usuaris de l'equip..."
groupadd -f greendevcorp

# Creem 4 usuaris assignant-los al grup principal 'greendevcorp'
for i in 1 2 3 4; do
    if ! id -u dev$i > /dev/null 2>&1; then
        useradd -m -s /bin/bash -g greendevcorp dev$i
        # Assignem una contrasenya per defecte per poder fer proves de login
        echo "dev$i:gsx$i" | chpasswd
    fi
done

# ==============================================================================
# PART B: DIRECTORIS I PERMISOS OCTALS
# ==============================================================================
echo "[+] Creant estructura de directoris col·laboratius..."
mkdir -p /home/greendevcorp/{bin,shared}
touch /home/greendevcorp/done.log

# El propietari és root, però el grup és l'equip de desenvolupadors
chown -R root:greendevcorp /home/greendevcorp

# 1. Directori 'bin': Només executable per membres de l'equip (Octal: 750)
chmod 750 /home/greendevcorp/bin

# 2. Directori 'shared': Apliquem SetGID (2) i Sticky Bit (1) -> 3000
# El grup base només tindrà lectura (5), donarem escriptura via ACL a dev1 i dev2.
chmod 3750 /home/greendevcorp/shared

# 3. Arxiu 'done.log': Tots llegeixen (4), només dev1 escriu (6)
chown dev1:greendevcorp /home/greendevcorp/done.log
chmod 644 /home/greendevcorp/done.log

# ==============================================================================
# PART C: ADVANCED ACCESS CONTROL (POSIX ACLs)
# ==============================================================================
echo "[+] Configurant ACLs (Llistes de Control d'Accés)..."
# Donem permís d'escriptura (rwx) només a dev1 i dev2. dev3 i dev4 només lectura (r-x)
setfacl -m u:dev1:rwx,u:dev2:rwx,u:dev3:r-x,u:dev4:r-x /home/greendevcorp/shared

# Apliquem ACLs per defecte (-d) perquè qualsevol arxiu nou hereti aquestes normes
setfacl -d -m u:dev1:rwx,u:dev2:rwx,u:dev3:r-x,u:dev4:r-x /home/greendevcorp/shared

# ==============================================================================
# PART D: LÍMITS DE RECURSOS (PAM)
# ==============================================================================
echo "[+] Fixant límits de recursos per als usuaris..."
cat <<EOF > /etc/security/limits.d/greendevcorp-team.conf
# Limits per a l'equip de desenvolupadors (Week 4)
@greendevcorp soft nproc 100
@greendevcorp hard nproc 200
@greendevcorp soft nofile 1024
@greendevcorp hard nofile 2048
@greendevcorp hard as 524288
EOF

# ==============================================================================
# PART E: PERSONALITZACIÓ DE L'ENTORN I SHELL
# ==============================================================================
echo "[+] Configurant variables d'entorn compartides (/etc/profile.d)..."
cat <<EOF > /etc/profile.d/greendevcorp_env.sh
# Configuració carregada automàticament per a qualsevol membre de l'equip
if groups | grep -q "\bgreendevcorp\b"; then
    export PATH="\$PATH:/home/greendevcorp/bin"
    alias ll='ls -lah'
    alias work='cd /home/greendevcorp/shared'
fi
EOF

echo "Configuració d'usuaris completada!"
