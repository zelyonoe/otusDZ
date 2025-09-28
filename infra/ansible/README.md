## Ansible Playbook for Yandex Cloud VM

This playbook configures a VM with base packages (`git`, `curl`, etc.) and NGINX. It can serve static content or proxy to an upstream app.

### Structure

```
infra/ansible/
  ansible.cfg
  site.yml
  inventory/
    local.ini
    example_yc.ini
  group_vars/
    all.yml
  roles/
    common/
      tasks/main.yml
    nginx/
      tasks/main.yml
      handlers/main.yml
      templates/default.j2
```

### Variables

- `nginx_server_name`: server_name, default `_`
- `nginx_listen_port`: default `80`
- `nginx_app_root`: static root, default `/var/www/app/public`
- `nginx_proxy_upstream`: if set (e.g. `http://127.0.0.1:3000`), NGINX proxies to it
- `enable_ufw`: enable firewall management (default `false`)

### Usage

Local (for syntax check / dry run):

```bash
cd infra/ansible
ansible-playbook -i inventory/local.ini site.yml --check -vv
```

Remote YC VM (replace IP and user/key as needed in `inventory/example_yc.ini`):

```bash
cd infra/ansible
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory/example_yc.ini site.yml -b -vv
```

To enable UFW:

```bash
ansible-playbook -i inventory/example_yc.ini site.yml -e enable_ufw=true -b
```

Logs are saved when you pipe output, e.g.:

```bash
ansible-playbook -i inventory/example_yc.ini site.yml -vv | tee ansible_run.log
```

