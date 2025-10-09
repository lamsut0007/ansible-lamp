# Configuration Management

This repository contains Ansible playbooks for system hardening and configuration management.

## Prerequisites

Before running the playbook, ensure that:

- Ansible is installed on your local machine.
- You need to fill your information to `inventory/hosts.ini` file.
- You know the `sudo` password for the target servers (if required).

### Run Playbooks

To execute a playbook, use the following command:

```bash
ansible-playbook playbooks/<playbook file name> -K
