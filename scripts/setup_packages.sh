#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Si us plau, executa'm fent servir root (su -) o sudo."
    exit 1
fi

echo "--- Instal·lant paquets i eines bàsiques ---"

# (1). ACTUALITZACIÓ I INSTAL·LACIÓ (Afegit nginx)
apt update && apt install -y sudo openssh-server git htop nginx
sudo apt update && sudo apt install -y rsync

# (2). PRIVILEGIS (Escalada segura)
if groups gsx | grep -q "\bsudo\b"; then
    echo "L'usuari gsx ja té permisos de sudo."
else
    usermod -aG sudo gsx
    echo "Usuari gsx afegit al grup sudo."
fi

# (3). ACTIVACIÓ DEL SERVEI SSH
systemctl enable --now ssh

# =========================================================================
# (4). CONFIGURACIÓ DE SERVEIS (WEEK 2) 
# =========================================================================
echo "--- Configurant serveis de la Week 2 (Nginx & Backup) ---"

# 4.1 Resiliència per a Nginx (Override)
mkdir -p /etc/systemd/system/nginx.service.d/
cp /opt/admin/configs/nginx-override.conf /etc/systemd/system/nginx.service.d/override.conf

# 4.2 Serveis i Timers de Backup (Enllaços simbòlics)
sudo ln -sf /opt/admin/configs/backup-gsx-24h.service /etc/systemd/system/backup-gsx-24h.service
sudo ln -sf /opt/admin/configs/backup-gsx-24h.timer /etc/systemd/system/backup-gsx-24h.timer

sudo ln -sf /opt/admin/configs/backup-gsx-72h.service /etc/systemd/system/backup-gsx-72h.service
sudo ln -sf /opt/admin/configs/backup-gsx-72h.timer /etc/systemd/system/backup-gsx-72h.timer

sudo ln -sf /opt/admin/configs/backup-gsx-7D.service /etc/systemd/system/backup-gsx-7D.service
sudo ln -sf /opt/admin/configs/backup-gsx-7D.timer /etc/systemd/system/backup-gsx-7D.timer

#Week 3, enllaç simbòlic per service de workload-simulator
sudo ln -sf /opt/admin/configs/workload-simulator.service /etc/systemd/system/workload-simulator.service

#Week 5, enllaç simbòlic per service de backup-incremental
sudo ln -sf /opt/admin/configs/backup-incremental.service /etc/systemd/system/backup-incremental.service
sudo ln -sf /opt/admin/configs/backup-incremental.timer /etc/systemd/system/backup-incremental.timer

# 4.3 Recarregar systemd perquè llegeixi els nous arxius
sudo systemctl daemon-reload

# 4.4 Activar l'Nginx i el Timer del Backup perquè arrenquin sols
systemctl enable --now nginx
systemctl restart nginx
systemctl enable --now backup-gsx-24h.timer
systemctl enable --now backup-gsx-72h.timer
systemctl enable --now backup-gsx-7D.timer
systemctl enable --now backup-incremental.timer
# 4.5 Configurar rotació de logs (Journald)
echo "Configurant límits de retenció de logs..."
mkdir -p /etc/systemd/journald.conf.d/
ln -sf /opt/admin/configs/journald-limits.conf /etc/systemd/journald.conf.d/99-limits.conf
systemctl restart systemd-journald

# 4.6 Límits d'Usuari PAM (Week 3)
echo "Configurant límits PAM per a l'usuari gsx..."
cat <<EOF | sudo tee /etc/security/limits.d/gsx-limits.conf > /dev/null
gsx hard nproc 400
gsx soft nproc 300
gsx hard nofile 4096
gsx soft nofile 1024
EOF


# 4.7 Personalització de l'entorn (Week 4)
echo "Configurant l'entorn de shell compartit..."
sudo ln -sf /opt/admin/configs/greendevcorp_env.sh /etc/profile.d/greendevcorp_env.sh

echo "--- Instal·lació i configuració de serveis completada. ---"
