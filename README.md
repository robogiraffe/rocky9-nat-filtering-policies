# rocky9-nat-filtering-policies

Configuring NAT and zone-based traffic filtering (LAN ↔ WAN) with firewalld

As of Rocky Linux 9, iptables and its associated utilities are deprecated, meaning they are no longer recommended for use and may be removed in future releases. Firewalld is the preferred tool for managing firewall rules and network traffic.

## NAT and Traffic Filtering Between LAN and WAN on Rocky Linux 9 with firewalld

### The Problem  

You set up a Rocky Linux 9 server with two interfaces (for example):

- **ens33 (WAN)** – connected to the internet (`192.168.122.2/24`),
- **ens34 (LAN)** – connected to the local network (`192.168.123.2/24`). 

The goal is simple: enable NAT so that clients on the LAN can reach the internet through this server.
At first glance, the configuration looks correct:
IP forwarding is enabled;
masquerading is active on the WAN zone;
LAN and WAN interfaces are placed into different firewalld zones (internal and public);
Yet, the clients cannot reach the internet.
When trying to **ping 8.8.8.8** from the LAN side, the response is: **Packet filtered**.

The NAT is working, but the traffic is blocked between zones.

### The Fix

Starting with Rocky Linux 9, firewalld enforces stricter zone separation.
Even with masquerading enabled, packets will not pass between zones unless you explicitly allow it.

The modern way to do this is with Policies.
A policy defines how traffic may flow from one zone to another.

Step 1. Enable IP forwarding

```
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl -p /etc/sysctl.d/99-ipforward.conf
```

Step 2. Assign interfaces to zones

```
sudo firewall-cmd --permanent --zone=public --change-interface=ens33
sudo firewall-cmd --permanent --zone=internal --change-interface=ens34
```

Step 3. Enable masquerading on WAN

```
sudo firewall-cmd --permanent --zone=public --add-masquerade
```
Step 4. Create a policy to allow LAN → WAN traffic and reload

```
sudo firewall-cmd --permanent --new-policy internal-to-public
sudo firewall-cmd --permanent --policy internal-to-public --set-target ACCEPT
sudo firewall-cmd --permanent --policy internal-to-public --add-ingress-zone internal
sudo firewall-cmd --permanent --policy internal-to-public --add-egress-zone public
sudo firewall-cmd --reload
```
