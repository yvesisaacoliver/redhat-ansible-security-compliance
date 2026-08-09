#!/bin/bash
# ══════════════════════════════════════════════
# Setup — Ansible Automation Platform Controller
# Red Hat 60-day Trial
# ══════════════════════════════════════════════
set -e

echo "══════════════════════════════════════════════"
echo " Ansible Automation Platform — Setup"
echo "══════════════════════════════════════════════"

# ── 1. Register with Red Hat ─────────────────
echo ""
echo "[1/6] Registrando no Red Hat..."
echo "  Trial: https://www.redhat.com/en/technologies/management/ansible/trial"
echo ""
read -p "  Username Red Hat: " RH_USER
read -sp "  Password Red Hat: " RH_PASS
echo ""

sudo subscription-manager register --username="$RH_USER" --password="$RH_PASS"
sudo subscription-manager attach --auto

# ── 2. Enable repos ─────────────────────────
echo ""
echo "[2/6] Habilitando repositórios..."
sudo subscription-manager repos \
  --enable ansible-automation-platform-2.5-for-rhel-9-x86_64-rpms \
  --enable rhel-9-for-x86_64-baseos-rpms \
  --enable rhel-9-for-x86_64-appstream-rpms

# ── 3. Install AAP ──────────────────────────
echo ""
echo "[3/6] Instalando Ansible Automation Platform..."
sudo dnf install -y ansible-automation-platform-installer

# ── 4. Install required collections ─────────
echo ""
echo "[4/6] Instalando Ansible collections necessárias..."
sudo dnf install -y ansible-core
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install ansible.eda

# ── 5. Configure installer ──────────────────
echo ""
echo "[5/6] Configurando instalação..."
INSTALLER_DIR=$(ls -d /opt/ansible-automation-platform/installer/*)
cd "$INSTALLER_DIR"

cat << 'HELP'

  Edite o arquivo 'inventory' neste diretório:
    $(pwd)/inventory

  Configurações mínimas:
    [automationcontroller]
    $(hostname -f) ansible_connection=local

    [automationeda]
    $(hostname -f) ansible_connection=local

    admin_password='SuaSenhaForte123!'
    pg_password='SuaSenhaPG123!'

HELP

read -p "  Pressione Enter quando tiver editado o inventory..."

# ── 6. Run installer ───────────────────────
echo ""
echo "[6/6] Instalando AAP (15-30 min)..."
sudo ./setup.sh

PUBLIC_IP=$(curl -s ifconfig.me)
echo ""
echo "══════════════════════════════════════════════"
echo " ✅ INSTALAÇÃO COMPLETA"
echo "══════════════════════════════════════════════"
echo ""
echo " Automation Controller: https://$PUBLIC_IP"
echo " Login: admin / (sua senha)"
echo ""
echo " Próximos passos:"
echo "   1. Upload subscription manifest"
echo "   2. Criar 3 Inventories (dev, staging, prod)"
echo "   3. Criar Credential (SSH key)"
echo "   4. Criar Project (apontar para playbooks)"
echo "   5. Criar 3 Job Templates (1 por ambiente)"
echo "   6. Criar 1 Workflow Template (dev→staging→prod)"
echo "   7. Configurar RBAC (Security Admin, DevOps, Auditor)"
echo "══════════════════════════════════════════════"
