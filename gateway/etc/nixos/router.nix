{ config, pkgs, ... }:

let
  internalInterface = "enp5s0";
  externalInterface = "enp2s0";
in
{
  users.users.mjh = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/mjh";
    description = "Matthew Hollick";
    initialPassword = "foobar";
  };

  networking.hostName = "router";
  networking.interfaces.${externalInterface} = {
    useDHCP = true;
  };
  networking.interfaces.${internalInterface} = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.13.1";
        prefixLength = 24;
      }
    ];
  };
  networking.nat = {
    enable = true;
    internalInterfaces = [ "${internalInterface}" ];
    externalInterface = "${externalInterface}";
    forwardPorts = [
      #k1
      { sourcePort = 1022; destination = "192.168.13.201:22"; }
      #k2
      { sourcePort = 2022; destination = "192.168.13.202:22"; }
      #k3
      { sourcePort = 3022; destination = "192.168.13.203:22"; }
      #k4
      { sourcePort = 4022; destination = "192.168.13.204:22"; }
    ];
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      domain-needed = true;
      dhcp-range = [
        "192.168.13.100,192.168.13.199"
      ];
      no-dhcp-interface = "${externalInterface}";
      dhcp-host = [
        "1B:5E:BE:6E:EE:58,k1,192.168.13.201"
	"75:15:A0:D8:76:AD,k2,192.168.13.202"
	"3A:36:04:44:3F:BB,k3,192.168.13.203"
      ];
      dhcp-option = [
        "option:router,192.168.13.1"
	"option:dns-server,192.168.13.1"
	"option:ntp-server,192.168.13.1"
      ];
    };
  };
  services.openntpd.enable = true;
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    rtx
    neovim
    htop
    git
    dig
  ];
  environment.interactiveShellInit = ''
    alias vim='nvim'
  '';
}
