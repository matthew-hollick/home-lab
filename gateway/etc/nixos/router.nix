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
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      domain-needed = true;
      dhcp-range = [ "192.168.13.100,192.168.13.199" ];
      no-dhcp-interface = "${externalInterface}";
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
