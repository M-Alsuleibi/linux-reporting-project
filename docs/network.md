# Lab Network Topology (VMware Fusion)

This repo is tested in a 4-VM lab with 3 isolated host-only networks and a router VM.

## Subnets
- Subnet A (vmnet2): 172.16.10.0/24
- Subnet B (vmnet3): 172.16.20.0/24
- Subnet C (vmnet4): 172.16.30.0/24
- Router has an additional NAT uplink (Internet Sharing)

## IP Plan
Router:
- ens160: 172.16.10.1/24
- ens224: 172.16.20.1/24
- ens256: 172.16.30.1/24
- ens161: DHCP (VMware NAT)

Main Server:
- 172.16.10.10/24, gateway 172.16.10.1

Client A:
- 172.16.20.10/24, gateway 172.16.20.1

Client B:
- 172.16.30.10/24, gateway 172.16.30.1

## Why a router VM?
- Required for routing across subnets
- Provides NAT so private subnets can download packages
- Later will enforce access-control policy (allow A, block B)

## Notes on portability

- Interface names may differ (ens160, enp0s3, etc.).
If needed, update the interface reference inside the scripts.

- The lab topology (VMware/Fusion networks, subnets, router) is not auto-created by this repo.