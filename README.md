# Configuration Management

This repository contains Ansible playbooks for system hardening and configuration management.

## Prerequisites

Before running the playbook, ensure that:

- Ansible is installed on your local machine.
- You have SSH access to the target servers.
- You know the `sudo` password for the target servers (if required).

## About Playbooks

The `hardening.yml` playbook applies security hardening and configuration best practices to your servers.

### Run the Playbook

To execute the playbook, use the following command:

```bash
ansible-playbook playbooks/hardening.yml -K
