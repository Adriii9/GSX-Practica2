# Configuració carregada automàticament per a qualsevol membre de l'equip
if groups | grep -q "\bgreendevcorp\b"; then
    export PATH="$PATH:/home/greendevcorp/bin"
    alias ll='ls -lah'
    alias work='cd /home/greendevcorp/shared'
fi
