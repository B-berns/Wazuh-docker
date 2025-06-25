#!/bin/bash
# Exit on error
set -e

# --- Step 1: Create sudoer user 'wazuh' with no password ---
echo "👤 Creating 'wazuh' user with passwordless sudo..."
if ! id "wazuh" &>/dev/null; then
    sudo useradd -m -s /bin/bash wazuh
    echo "wazuh ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/wazuh
    sudo chmod 440 /etc/sudoers.d/wazuh
else
    echo "User 'wazuh' already exists. Skipping user creation."
fi

# --- Step 2: Update system ---
echo "🔄 Updating packages..."
sudo dnf update -y
sudo dnf upgrade -y

# --- Step 3: Install Git ---
echo "📦 Installing Git..."
sudo dnf install -y git

# --- Step 4: Install Docker and Docker Compose plugin ---
echo "🐳 Installing Docker & Compose..."

# Remove old Docker if any
sudo dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine || true

# Add Docker repo
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker packages
sudo dnf install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Enable Docker
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker wazuh

# --- Step 5: Switch to 'wazuh' user to deploy Wazuh stack ---
echo "🔁 Switching to 'wazuh' user..."

sudo -i -u wazuh bash <<'EOF'
set -e

# Clone Wazuh repo
echo "📥 Cloning Wazuh Docker repo..."
git clone https://github.com/wazuh/wazuh-docker.git -b v4.12.0
EOF

echo "✅ Wazuh setup complete!"
echo "➡️ Log in as 'wazuh' or run: su - wazuh "
ECHO " Move into single-node directory "
ECHO
ECHO
ECHO "cd wazuh-docker/single-node"

# Generate certificates inside single-node
echo "🔐 Generating certificates..."
ECHO
ECHO
ECHO "docker compose -f generate-indexer-certs.yml run --rm generator"

# Start the stack
echo "🚀 Start the wazuh..."
echo "docker compose up -d"


# --- Step 6: Done ---

