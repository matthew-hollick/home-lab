# home-lab - Kubernetes

## Objectives
- Create a NixOS based 2 interface Nat gateway
  - Providing DNS, DHCP, TFTPD, HTTP services to the internal network
- Create a simple Kubernetes cluster with Cillium network management.


0. Deploy a gateway server using the nix configuration.
1. Use the scripts under gateway/var/lib/(dnsmasq|www) to download additional components.
2. Boot what will become the kubernetes cluster leader.
3. ssh to the cluster leader, observe that the kubeadm service has been started successfully.
4. Download the Cillium network configuration and apply it.

