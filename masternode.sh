#!/bin/bash

###############################################################################
# BRDPoSChain Masternode One-Click Installer
# Automated setup script for masternode deployment
#
# Version: 1.0.0
# SHA256: (will be generated on release)
# Source: https://github.com/BirrFoundation/BRDPoSChain
#
# SECURITY NOTICE:
# - Always review this script before running
# - Verify the source URL is correct
# - Check the SHA256 hash matches official release
# - Only run on dedicated masternode servers
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WALLET_ADDRESS="${1:-}"
NODE_NAME="brc-masternode"
IMAGE_NAME="birr/brc-node:latest"
DATA_DIR="/var/lib/brdpos"
P2P_PORT=30303
RPC_PORT=8545

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║        BRDPoSChain Masternode One-Click Installer             ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

###############################################################################
# Validation
###############################################################################

validate_wallet() {
    if [ -z "$WALLET_ADDRESS" ]; then
        print_error "Wallet address is required!"
        echo ""
        echo "Usage: curl -fsSL https://setup.birrfoundation.org/masternode.sh | bash -s -- YOUR_WALLET_ADDRESS"
        exit 1
    fi

    # Basic validation (starts with 0x and is 42 characters)
    if [[ ! "$WALLET_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        print_error "Invalid wallet address format!"
        echo "Expected format: 0x followed by 40 hexadecimal characters"
        exit 1
    fi

    print_success "Wallet address validated: $WALLET_ADDRESS"
}

###############################################################################
# System Detection
###############################################################################

detect_os() {
    print_step "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        print_success "Detected: $PRETTY_NAME"
    elif [ "$(uname)" == "Darwin" ]; then
        OS="macos"
        print_success "Detected: macOS"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
}

###############################################################################
# Docker Installation
###############################################################################

install_docker() {
    print_step "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed ($(docker --version))"
        return 0
    fi

    print_step "Installing Docker..."
    
    case "$OS" in
        ubuntu|debian)
            curl -fsSL https://get.docker.com | sh
            systemctl enable docker
            systemctl start docker
            ;;
        centos|rhel|fedora)
            curl -fsSL https://get.docker.com | sh
            systemctl enable docker
            systemctl start docker
            ;;
        macos)
            print_error "Please install Docker Desktop for Mac manually from https://www.docker.com/products/docker-desktop"
            exit 1
            ;;
        *)
            print_error "Unsupported OS for automatic Docker installation"
            exit 1
            ;;
    esac
    
    print_success "Docker installed successfully"
}

###############################################################################
# Firewall Configuration
###############################################################################

configure_firewall() {
    print_step "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow $P2P_PORT/tcp comment "BRDPoS P2P"
        ufw allow $RPC_PORT/tcp comment "BRDPoS RPC"
        print_success "UFW firewall rules added"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$P2P_PORT/tcp
        firewall-cmd --permanent --add-port=$RPC_PORT/tcp
        firewall-cmd --reload
        print_success "Firewalld rules added"
    else
        print_warning "No firewall detected. Please manually open ports $P2P_PORT and $RPC_PORT"
    fi
}

###############################################################################
# Node Deployment
###############################################################################

deploy_node() {
    print_step "Deploying BRDPoSChain masternode..."
    
    # Stop and remove existing container if it exists
    if docker ps -a | grep -q $NODE_NAME; then
        print_step "Removing existing container..."
        docker stop $NODE_NAME 2>/dev/null || true
        docker rm $NODE_NAME 2>/dev/null || true
    fi
    
    # Create data directory
    mkdir -p $DATA_DIR
    
    # Pull latest image
    print_step "Pulling latest node image..."
    docker pull $IMAGE_NAME
    
    # Run container
    print_step "Starting masternode container..."
    docker run -d \
        --name $NODE_NAME \
        --restart unless-stopped \
        -p $P2P_PORT:$P2P_PORT \
        -p $RPC_PORT:$RPC_PORT \
        -v $DATA_DIR:/root/.brc \
        $IMAGE_NAME \
        --masternode \
        --wallet $WALLET_ADDRESS \
        --network mainnet \
        --rpc \
        --rpcaddr 0.0.0.0 \
        --rpcport $RPC_PORT \
        --port $P2P_PORT \
        --syncmode full \
        --gcmode archive
    
    print_success "Masternode container started"
}

###############################################################################
# Health Check
###############################################################################

health_check() {
    print_step "Performing health check..."
    
    sleep 5
    
    if docker ps | grep -q $NODE_NAME; then
        print_success "Container is running"
    else
        print_error "Container failed to start"
        echo ""
        echo "Logs:"
        docker logs $NODE_NAME
        exit 1
    fi
    
    # Check if RPC is responding
    print_step "Checking RPC endpoint..."
    sleep 10
    
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:$RPC_PORT > /dev/null 2>&1; then
        print_success "RPC endpoint is responding"
    else
        print_warning "RPC endpoint not responding yet (this is normal, it may take a few minutes)"
    fi
}

###############################################################################
# Setup Monitoring
###############################################################################

setup_monitoring() {
    print_step "Setting up monitoring script..."
    
    cat > /usr/local/bin/brc-status << 'EOF'
#!/bin/bash
echo "=== BRDPoSChain Masternode Status ==="
echo ""
echo "Container Status:"
docker ps | grep brc-masternode || echo "Container not running!"
echo ""
echo "Latest Logs (last 20 lines):"
docker logs --tail 20 brc-masternode
echo ""
echo "Current Block:"
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "RPC not responding"
echo ""
echo "Peer Count:"
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "RPC not responding"
EOF
    
    chmod +x /usr/local/bin/brc-status
    print_success "Monitoring script installed at /usr/local/bin/brc-status"
}

###############################################################################
# Main Installation Flow
###############################################################################

main() {
    print_header
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (use sudo)"
        exit 1
    fi
    
    validate_wallet
    detect_os
    install_docker
    configure_firewall
    deploy_node
    health_check
    setup_monitoring
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║              ✓ Installation Complete!                         ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Masternode Details:${NC}"
    echo -e "  Wallet Address: ${YELLOW}$WALLET_ADDRESS${NC}"
    echo -e "  Container Name: ${YELLOW}$NODE_NAME${NC}"
    echo -e "  P2P Port: ${YELLOW}$P2P_PORT${NC}"
    echo -e "  RPC Port: ${YELLOW}$RPC_PORT${NC}"
    echo -e "  Data Directory: ${YELLOW}$DATA_DIR${NC}"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "  View logs:        ${YELLOW}docker logs -f $NODE_NAME${NC}"
    echo -e "  Check status:     ${YELLOW}brc-status${NC}"
    echo -e "  Restart node:     ${YELLOW}docker restart $NODE_NAME${NC}"
    echo -e "  Stop node:        ${YELLOW}docker stop $NODE_NAME${NC}"
    echo -e "  Start node:       ${YELLOW}docker start $NODE_NAME${NC}"
    echo ""
    echo -e "${GREEN}Your masternode is now running and syncing with the network!${NC}"
    echo -e "${YELLOW}Note: Initial sync may take several hours depending on blockchain size.${NC}"
    echo ""
}

main

