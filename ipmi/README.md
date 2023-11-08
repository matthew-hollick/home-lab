# IPMI

Note: Supermicro BMC needs the option `-I lanplus`
```
# Show network details for the BMC
ipmitool -H 192.168.13.100 -I lanplus -U ADMIN -P ADMIN lan print

# Show Mac address of first network adaptor
ipmitool -H 192.168.13.100 -I lanplus -U ADMIN -P ADMIN raw 0x30 0x21

# Power status
ipmitool -H 192.168.13.100 -I lanplus -U ADMIN -P ADMIN power status

# Set the next and all future boots to use the local disk as the boot device (the persistent option might not work..)
ipmitool -H 192.168.13.100 -I lanplus  -U ADMIN -P ADMIN chassis bootdev disk options=persistent

# Set the next boot to use network PXE
ipmitool -H 192.168.13.100 -I lanplus -U ADMIN -P ADMIN chassis bootdev pxe

# Shut down the CPU
ipmitool -H 192.168.13.100 -I lanplus -U ADMIN -P ADMIN power off

# Start the CPU
ipmitool -H 192.168.13.100 -I lanplus -U ADMIN -P ADMIN power on

```
