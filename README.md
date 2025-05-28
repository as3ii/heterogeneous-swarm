# Create a Docker Swarm cluster using one or more ARM64 devices and VMs on Proxmox

## How to use this repo

### Generic

- Manually install `opentofu`, `ansible` and `just` on your computer.
- Clone this repo and `cd` in it.
- In the `terraform/` folder `cp credentials.auto.tfvars.template credentials.auto.tfvars`
  and fill the new file with your credentials and required data for the Proxmox host.
- In the root of the project run `just tdeploy` to create the VMs.
- While the container is creating, you can go in the `ansible/` folder, run
  `cp inventory.template inventory` and configure your private ssh key file and the IP
  of the newly created VMs and the ARM64 devices.
- In the root of the project run `just adeploy` to configure the cluster
- Next you can use the cluster as you please

### Using nix (w/ direnv)

- Enable the experimental nix-command and flakes, if not already done.
- Follow the generic instructions skipping the first step, direnv will
  automatically install all the dependencies.

### Using nix (w/o direnv)

- Enable the experimental nix-command and flakes, if not already done.
- Next clone this repo, `cd` in it and run `nix develop`
- Follow the generic instructions skipping the first 2 steps

## Cluster structure
TODO
