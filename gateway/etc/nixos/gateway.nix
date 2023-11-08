{ config, pkgs, ... }:

let
  internalInterface = "enp5s0";
  externalInterface = "enp2s0";

  switchMac = "80:cc:9c:9c:cd:27";
  switchIp = "192.168.13.10";

  k1Eth0Mac = "00:25:90:de:82:ca";
  k1Eth1Mac = "00:25:90:de:82:cb";
  k1IpmiMac = "00:25:90:de:7f:fb";
  k1Eth0Ip  = "192.168.13.201";
  k1Eth1Ip  = "192.168.13.211";
  k1IpmiIp  = "192.168.13.11";

  k2Eth0Mac = "b";
  k2Eth1Mac = "b";
  k2IpmiMac = "b";
  k2Eth0Ip  = "192.168.13.202";
  k2Eth1Ip  = "192.168.13.212";
  k2IpmiIp  = "192.168.13.12";

  k3Eth0Mac = "c";
  k3Eth1Mac = "c";
  k3IpmiMac = "c";
  k3Eth0Ip  = "192.168.13.203";
  k3Eth1Ip  = "192.168.13.213";
  k3IpmiIp  = "192.168.13.13";

  k4Eth0Mac = "d";
  k4Eth1Mac = "d";
  k4IpmiMac = "d";
  k4Eth0Ip  = "192.168.13.204";
  k4Eth1Ip  = "192.168.13.214";
  k4IpmiIp  = "192.168.13.14";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };
  virtualisation.docker.enable = true;
  networking = {
    hostName = "zaphod";
    interfaces = {
      ${externalInterface} = {
        useDHCP = true;
      };
      ${internalInterface} = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.13.1";
            prefixLength = 24;
          }
        ];
      };
    };
    nftables.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 22 53 180 1022 2022 3022 4022 8080 8081 ];
      allowedUDPPorts = [ 53 67 68 69 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "${internalInterface}" ];
      internalIPs = [ "192.169.13.0/24" ];
      externalInterface = "${externalInterface}";
      forwardPorts = [
        #k1
        { sourcePort = 1022; destination = "${k1Eth0Ip}:22"; }
        #k2
        { sourcePort = 2022; destination = "${k2Eth0Ip}:22"; }
        #k3
        { sourcePort = 3022; destination = "${k3Eth0Ip}:22"; }
        #k4
        { sourcePort = 4022; destination = "${k4Eth0Ip}:22"; }
	#switch
	{ sourcePort = 180;  destination = "${switchIp}:80"; }
      ];
    };
  };
  systemd.services.dnsmasq.serviceConfig = {
    User = "dnsmasq";
    Group = "dnsmasq";
    StateDirectory = "dnsmasq/tftpboot";
    StateDirectoryMode = "0750";
  };
  services = {
    dnsmasq = {
      enable = true;
      settings = {
        domain-needed = true;
	log-queries = true;
	log-dhcp = true;
        dhcp-range = [
          "192.168.13.100,192.168.13.199"
        ];
        no-dhcp-interface = "${externalInterface}";
        enable-tftp = true;
        tftp-root = "/var/lib/dnsmasq/";
	dhcp-match = [
          "set:bios,option:client-arch,0"
	  "set:efi32,option:client-arch,6"
	  "set:efibc,option:client-arch,7"
	  "set:efi64,option:client-arch,9"
	];
        dhcp-userclass = "set:ipxe,iPXE";
        dhcp-boot = [
	  "tag:bios,undionly.kpxe"
	  "tag:efi32,ipxe.efi"
	  "tag:efibc,ipxe.efi"
	  "tag:efi64,ipxe.efi"
	  "tag:ipxe,http://192.168.13.1:8080/boot.ipxe"
	];
        dhcp-host = [
          "${k1Eth0Mac},k1,${k1Eth0Ip}"
	  "${k1IpmiMac},i1,${k1IpmiIp}"
	  "${k2Eth0Mac},k2,${k2Eth0Ip}"
	  "${k2IpmiMac},i1,${k2IpmiIp}"
	  "${k3Eth0Mac},k3,${k3Eth0Ip}"
	  "${k3IpmiMac},i1,${k3IpmiIp}"
	  "${k4Eth0Mac},k4,${k4Eth0Ip}"
	  "${k4IpmiMac},i1,${k4IpmiIp}"
	  "${switchMac},switch,${switchIp}"
        ];
        dhcp-option = [
          "option:router,192.168.13.1"
          "option:dns-server,192.168.13.1"
	  "option:ntp-server,192.168.13.1"
        ];
      };
    };
    openntpd.enable = true;
    openssh.enable = true;
    # need to implement a webserver for the ipxe stuff and ignition file.
  };

  environment.systemPackages = with pkgs; [
    rtx
    neovim
    htop
    tree
    git
    gnupg
    dig
    wget
    openssl
    nmap
    arping
    arp-scan
    ipmitool
    wol
    inetutils
    docker
    syslinux
  ];
  environment.interactiveShellInit = ''
    alias vim='nvim'
  '';

  users.users.mjh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    home = "/home/mjh";
    description = "Matthew Hollick";
    initialPassword = "foobar";
  };
}
