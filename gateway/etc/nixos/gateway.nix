{ config, pkgs,  ... }:

let

  hostname = "zaphod";
  hostip = "192.168.13.1";
  internalInterface = "enp5s0";
  externalInterface = "enp2s0";
  docroot = "/var/lib/www";

  switchMac = "80:cc:9c:9c:cd:27";
  switchIp = "192.168.13.10";

  k1Eth0Mac = "00:25:90:de:82:ca";
  k1Eth1Mac = "00:25:90:de:82:cb";
  k1IpmiMac = "00:25:90:de:7f:fb";
  k1Eth0Ip  = "192.168.13.201";
  k1Eth1Ip  = "192.168.13.211";
  k1IpmiIp  = "192.168.13.11";
  
  k2Eth0Mac = "00:25:90:de:83:06";
  k2Eth1Mac = "b";
  k2IpmiMac = "00:25:90:de:80:19";
  k2Eth0Ip  = "192.168.13.202";
  k2Eth1Ip  = "192.168.13.212";
  k2IpmiIp  = "192.168.13.12";

  k3Eth0Mac = "00:25:90:de:80:c6";
  k3Eth1Mac = "c";
  k3IpmiMac = "00:25:90:de:7e:f9";
  k3Eth0Ip  = "192.168.13.203";
  k3Eth1Ip  = "192.168.13.213";
  k3IpmiIp  = "192.168.13.13";
  
  k4Eth0Mac = "00:25:90:de:82:da";
  k4Eth1Mac = "d";
  k4IpmiMac = "00:25:90:de:80:03";
  k4Eth0Ip  = "192.168.13.204";
  k4Eth1Ip  = "192.168.13.214";
  k4IpmiIp  = "192.168.13.14";

  pxelinuxcfg = pkgs.writeText "pxelinuxcfgdefault" ''
    DEFAULT menu
    PROMPT 0
    MENU TITLE PXE Boot Menu
    TIMEOUT 600
    TOTALTIMEOUT 6000
    ONTIMEOUT FlatCar
    LABEL FlatCar
      MENU LABEL ^1. Boot Flatcar Linux
      KERNEL ipxe.lkrn
      APPEND dhcp && chain http://${hostip}:8080/flatcar.ipxe
    LABEL FlatCar-Install
      MENU LABEL ^2. Boot Flatcar Linux Installer
      KERNEL ipxe.lkrn
      APPEND dhcp && chain http://${hostip}:8080/flatcat-install.ipxe
  '';

  ipxebootfile = pkgs.writeText "boot.ipxe" ''
    #!ipxe
    echo Client Fields___ Option_ Value_________________________________________________
    echo manufacturer.... ....... ''${manufacturer}
    echo product......... ....... ''${product}
    echo serial.......... ....... ''${serial}
    echo asset........... ....... ''${asset}
    echo mac............. ....... ''${mac}
    echo uuid............ 097.... ''${uuid}
    echo busid........... 175.177 ''${busid}#can be used to chainload
    echo user class...... 077.... ''${user-class}
    echo DHCP Fields_____ Option_ Value_________________________________________________
    echo dhcp-server..... 054.... ''${dhcp-server}
    echo domain.......... 015.... ''${domain}
    echo hostname........ 012.... ''${hostname}
    echo ip.............. 050.... ''${ip}
    echo netmask......... 001.... ''${netmask}
    echo gateway......... 003.... ''${gateway}
    echo dns............. 006.... ''${dns}
    echo ntp-server...... 042.... ''${42:ipv4}
    echo next-server..... 066.... ''${next-server}
    echo filename........ 067.... ''${filename}
    sleep 30
    set boot-host http://192.168.13.1:8080
    set assets-url ''${boot-host}/assets/flatcar/current
    set ignition-url ''${boot-host}/ignition
    set ignition-file ''${hostname}
    kernel ''${assets-url}/flatcar_production_pxe.vmlinuz initrd=flatcar_production_pxe_image.cpio.gz flatcar.first_boot=1 flatcar.autologin ignition.config.url=''${ignition-url}/''${ignition-file}.json
    initrd ''${assets-url}/flatcar_production_pxe_image.cpio.gz
    boot
  '';
in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };
  virtualisation.docker.enable = true;
  networking = {
    hostName = "${hostname}";
    extraHosts = ''
    192.168.13.1 zaphod zaphod.k8s.test.hedgehog gateway
    '';
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
  systemd.services = {
    dnsmasq = {
      serviceConfig = {
        ExecStartPre = [
          "/run/current-system/sw/bin/mkdir -p /var/lib/dnsmasq/pxelinux.cfg"
          "/run/current-system/sw/bin/mkdir -p /var/lib/dnsmasq/tftpboot"
          "/run/current-system/sw/bin/install -m 0644 ${pxelinuxcfg} /var/lib/dnsmasq/pxelinux.cfg/default"
        ];
      };
    };
    nginx = {
      serviceConfig = {
        StateDirectory = "www";
        StateDirectoryMode = "0750";
        ExecStartPre = [
          "/run/current-system/sw/bin/mkdir -p /var/lib/www/assets"
	  "/run/current-system/sw/bin/mkdir -p /var/lib/www/ignition"
          "/run/current-system/sw/bin/install -m 0644 ${ipxebootfile} /var/lib/www/boot.ipxe"
        ];
      };
    };
  };
  services = {
    dnsmasq = {
      enable = true;
      settings = {
        server = [ "192.168.3.1" ];
        domain-needed = true;
	domain = "k8s.test.hedgehog";
	local = "/k8s.test.hedgehog/";
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
	  "${k2IpmiMac},i2,${k2IpmiIp}"
	  "${k3Eth0Mac},k3,${k3Eth0Ip}"
	  "${k3IpmiMac},i3,${k3IpmiIp}"
	  "${k4Eth0Mac},k4,${k4Eth0Ip}"
	  "${k4IpmiMac},i4,${k4IpmiIp}"
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
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      defaultHTTPListenPort = 8080;
      virtualHosts = {
        ${hostname} = {
          root = "${docroot}";
	};
      };
    };
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
    tshark
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
