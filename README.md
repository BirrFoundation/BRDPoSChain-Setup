# 🚀 BRDPoSChain Masternode One-Click Installer

Automated setup script for deploying BRDPoSChain masternodes with a single command.

## ✨ Features

- ✅ **One-Click Installation** - Deploy a masternode in 5-10 minutes
- ✅ **Automatic OS Detection** - Supports Ubuntu, Debian, CentOS, RHEL, Fedora
- ✅ **Docker Auto-Install** - Installs Docker if not present
- ✅ **Firewall Configuration** - Automatically opens required ports
- ✅ **Health Checks** - Verifies node is running correctly
- ✅ **Monitoring Tools** - Built-in `brc-status` command
- ✅ **Auto-Restart** - Node automatically restarts on failure
- ✅ **Production-Ready** - Secure, tested, and reliable

## 🔒 Security

- **Version:** 1.0.0
- **SHA256:** (Will be updated after first release)
- **Source:** Open source and auditable
- **HTTPS Delivery:** Served over secure connection
- **Hash Verification:** Always verify before running

## 📋 Requirements

- **OS:** Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+, Fedora 34+
- **RAM:** 4GB minimum (8GB recommended)
- **CPU:** 2 cores minimum (4 cores recommended)
- **Storage:** 40GB minimum (100GB recommended)
- **Network:** Ports 30303 (P2P) and 8545 (RPC) must be accessible

## 🚀 Quick Install

### Option 1: One-Click Install (Recommended)

```bash
curl -fsSL https://birrfoundation.github.io/BRDPoSChain-Setup/masternode.sh | bash -s -- YOUR_WALLET_ADDRESS
```

### Option 2: Secure Install (Verify Hash First)

```bash
# Download script
wget https://birrfoundation.github.io/BRDPoSChain-Setup/masternode.sh

# Verify SHA256 hash (check website for current hash)
echo "HASH_HERE  masternode.sh" | sha256sum -c

# Make executable
chmod +x masternode.sh

# Run installer
./masternode.sh YOUR_WALLET_ADDRESS
```

## 📖 What the Script Does

1. **Validates** your wallet address format
2. **Detects** your operating system
3. **Installs** Docker (if not already installed)
4. **Configures** firewall rules (opens ports 30303, 8545)
5. **Pulls** the BRDPoSChain Docker image
6. **Deploys** the masternode container
7. **Performs** health checks
8. **Sets up** monitoring tools

## 🔧 Post-Installation

```bash
# Check status
brc-status

# View logs
docker logs -f brc-masternode

# Check sync progress
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

## 📞 Support

- **Website:** https://birrfoundation.org
- **GitHub Issues:** https://github.com/BirrFoundation/BRDPoSChain-Setup/issues

---

**Made with ❤️ by BirrFoundation**
