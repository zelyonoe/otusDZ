# Ansible provisioning for Yandex Cloud VM

This Ansible project configures a Yandex Cloud VM (or any Ubuntu/Debian host) with:

- Nginx
- Git
- Base dependencies (curl, unzip, build-essential, python3, etc.)

All configs live alongside the application repo in `ansible/`.

## Project structure

```
ansible/
  ansible.cfg
  inventory/
    local.ini
    yc.ini
  group_vars/
    all.yml
  playbooks/
    site.yml
  roles/
    base/
      tasks/main.yml
    git/
      tasks/main.yml
    nginx/
      defaults/main.yml
      handlers/main.yml
      tasks/main.yml
      templates/site.conf.j2
```

## Requirements

- Control node: Python 3.8+, Ansible 2.16+
- SSH access to YC VM (e.g., `ubuntu` user with your SSH key)

Install Ansible in a virtualenv (recommended):

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
pip install "ansible-core>=2.16,<2.17"
ansible --version
```

## Inventory

Edit `inventory/yc.ini` and set the external IP:

```
[yc]
vm1 ansible_host=203.0.113.10 ansible_user=ubuntu
```

For local dry-run (no changes applied):

```
[local]
localhost ansible_connection=local
```

## Variables

Defaults are in `group_vars/all.yml`:

- `app_user`: system user to own files (default: `app`)
- `app_root_dir`: web root (default: `/var/www/app`)
- `nginx_server_name`: server_name for nginx (default: `_`)
- `nginx_site_name`: site id (default: `app`)
- `nginx_listen_port`: default `80`
- `enable_ufw`: enable firewall (default: `false`)

Override on the command line if needed, e.g.:

```bash
ansible-playbook -i inventory/yc.ini playbooks/site.yml \
  -e "nginx_server_name=example.com app_root_dir=/var/www/app"
```

## Run

Syntax check:

```bash
ansible-playbook -i inventory/local.ini playbooks/site.yml --syntax-check
```

Local dry-run (check mode, no changes):

```bash
ansible-playbook -i inventory/local.ini playbooks/site.yml -C -vv
```

Run against Yandex Cloud VM:

```bash
ansible-playbook -i inventory/yc.ini playbooks/site.yml -vv
```

If your sudo requires a password, add `-K` to prompt.

## Collections

Install required collections into `collections/`:

```bash
ansible-galaxy collection install -r requirements.yml -p collections
```


