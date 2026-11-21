# Ansible

Updated: 2026-11-21

## TL;DR
- **Ansible** configures machines that already run. You describe the **state you want** and it fixes only what doesn't match.
- In this lab it's **Milestone 4**: it updates, hardens and checks `debian-01` over SSH from your Mac.
- The key idea is **idempotency**: run it twice, and the second run changes nothing.

## What you have

`Packer` ➔ `OpenTofu` ➔ `cloud-init` ➔ `Ansible`

1. **Packer** bakes template `9000` (Debian 13 + `openssh-server`, `cloud-init`, `qemu-guest-agent`).
2. **OpenTofu** clones it into VMs (`tofu/terraform.tfvars`).
3. **cloud-init** sets the hostname, user, key and sudo on first boot (`tofu/cloud-init/user-data.yaml.tftpl`).
4. **Ansible** is installed on your Mac (`ansible-core 2.21.6`) but **not used yet**.

**Live state of `debian-01`** (checked 2026-11-21):

| Check | Value | Ansible needs it? |
| --- | --- | --- |
| VM | `201`, 2 vCPU / 2 GB / 20 GB, `192.168.1.201` | — |
| SSH | `duane@192.168.1.201`, key only | ✅ to connect |
| sudo | passwordless (`NOPASSWD:ALL`) | ✅ for `become` |
| Python | 3.13.5 | ✅ runs the modules |
| `PasswordAuthentication` | `no` (cloud-init set it) | — |
| `PermitRootLogin` | `without-password`: **root can still log in with a key** | Ansible closes this |

**Who owns what:**

> Proxmox host `pve`
> > VM hardware: CPU, RAM, disk, IP. **OpenTofu**
> > > OS image: base packages. **Packer**
> > > > First-boot identity: user, key, hostname. **cloud-init**
> > > > > Everything inside the running OS, forever. **Ansible**

## Why not just SSH in or write a bash script?
- **Typing by hand**: you forget what you did, and VMs drift apart into one-off "snowflakes".
- **Bash scripts**: they describe **actions**, not **outcomes**.
  - `echo "PermitRootLogin no" >> sshd_config` run twice ↳ the line is in the file twice.
  - To make a script safe to re-run, you hand-write an `if` before every step.
- **Ansible**: modules check first, then change only what's needed ↳ safe to re-run forever.

## How it works

`Mac reads playbook` ➔ `SSH in` ➔ `push Python module` ➔ `run with sudo` ➔ `JSON result` ➔ `print status`

1. Ansible reads `playbook.yml` and `inventory.ini` on your Mac (the **control node**).
2. It SSHes to each **managed node** as `duane`. Nothing is installed on the VM (**agentless**).
3. It copies a small Python program for the task into `~/.ansible/tmp/`.
4. It runs the program, with sudo if `become: true`. The program checks the current state and changes it only if needed.
5. The program returns JSON such as `{"changed": false}`. The temp file is deleted.
6. Ansible prints the result and moves to the next task.

**Status colors:**

| Color | Status | Meaning |
| --- | --- | --- |
| Green | `ok` | Already correct, nothing done |
| Yellow | `changed` | Ansible fixed something |
| Cyan | `skipping` | A `when:` condition was false |
| Red | `failed` | The task broke. The play stops for that host |

## Terms

| Term | Plain meaning | Example | Could look like |
| --- | --- | --- | --- |
| **Control node** | Machine running Ansible | Your Mac | A VM in the lab that runs Ansible on a schedule |
| **Managed node** | Machine being configured | `debian-01` | `debian-02`, the Proxmox host `pve`, a Raspberry Pi. Anything with SSH + Python |
| **Inventory** | Address book of hosts and groups | `ansible/inventory.ini` | The same thing as YAML (`inventory.yml`), or a plugin that asks the Proxmox API for VMs |
| **Group** | Named set of hosts you target | `[debian]` | `[ubuntu]` for Ubuntu VMs, `[docker]` by job. One host can be in several groups |
| **Module** | Built-in tool that manages one kind of thing, idempotently | `apt`, `copy`, `service`, `user`, `reboot` | `dnf` on Fedora, `template` for files with variables, `docker_container` |
| **Task** | One module call with a name, one checklist item | "Harden SSH" | "Install Docker", "Open port 443 in the firewall" |
| **Play** | Tasks aimed at a group | "Update and harden Debian VMs" | A second play in the same file with `hosts: docker` |
| **Playbook** | YAML file of plays | `ansible/playbook.yml` | `site.yml` that imports `base.yml` + `docker.yml` |
| **become** | Ansible's word for sudo | `become: true` | `become_user: postgres` to run as a different user |
| **Handler** | Task that runs only when notified, once, at the end | "Restart SSH" | "Reload nginx" after its config changes |
| **Facts** | Host info gathered automatically | `ansible_distribution` = `Debian` | `when: ansible_distribution == "Ubuntu"` to skip a task on other OSes |
| **Variable** | A value inserted with `{{ }}` | `{{ ansible_user }}` = `duane` | `group_vars/ubuntu.yml` with `ansible_user: ubuntu` |
| **Idempotent** | Re-running changes nothing | Run 2 shows `changed=0` | — |
| **Role** | Packaged, reusable set of tasks | None yet | `roles/ssh_hardening/` reused by every play |

## What if

### Adding Ubuntu VMs
Yes, that's a **separate group**. Groups can also contain other groups.
```ini
[debian]
debian-01 ansible_host=192.168.1.201

[ubuntu]
ubuntu-01 ansible_host=192.168.1.210

# a group made of groups
[linux:children]
debian
ubuntu
```
- `hosts: linux` ↳ runs on both.
- `hosts: ubuntu` ↳ runs only on Ubuntu.
- `ansible-playbook playbook.yml --limit ubuntu` ↳ narrows any run on the fly.

### Hosts as plain IP addresses
The **inventory** holds the addresses, never the playbook. A friendly name is optional:
```ini
[debian]
192.168.1.201
192.168.1.209
```
- Works the same, but output says `192.168.1.201` instead of `debian-01`.
- A playbook only names **groups** (`hosts: debian`), so it never changes when IPs do.

### Different settings per group
Put them in files named after the group, next to the inventory:

| File | Contents | Applies to |
| --- | --- | --- |
| `group_vars/debian.yml` | `ansible_user: duane` | Every host in `[debian]` |
| `group_vars/ubuntu.yml` | `ansible_user: ubuntu` | Every host in `[ubuntu]` |
| `host_vars/debian-01.yml` | `ansible_port: 2222` | Only `debian-01` |

### One task, different OSes
Use **facts** to branch when a package name differs:
```yaml
- name: Install firewall (Debian)
  ansible.builtin.apt:
    name: nftables
  when: ansible_distribution == "Debian"
```

## Try it

### 1. Ad-hoc commands (read-only, safe now)
The trailing comma in `192.168.1.201,` means "a list of hosts", not an inventory file.

| Command | Expect |
| --- | --- |
| `ansible all -i 192.168.1.201, -u duane -m ping` | `"ping": "pong"` (proves SSH + Python work, not ICMP) |
| `ansible all -i 192.168.1.201, -u duane -m command -a "whoami"` | `duane` |
| `... -m command -a "whoami" --become` | `root` |
| `... -m setup -a "filter=ansible_distribution*"` | `Debian`, `13` |
| `... --become -m apt -a "name=qemu-guest-agent state=present"` | green, `"changed": false`: your first look at idempotency |

### 2. Project files

| File | Job |
| --- | --- |
| `ansible/ansible.cfg` | Defaults, so you skip flags |
| `ansible/inventory.ini` | Where the hosts are and how to log in |
| `ansible/playbook.yml` | The checklist |

**`ansible/ansible.cfg`**
```ini
[defaults]
inventory = inventory.ini
interpreter_python = auto_silent
```

**`ansible/inventory.ini`**
```ini
[debian]
debian-01 ansible_host=192.168.1.201

[debian:vars]
ansible_user=duane
ansible_ssh_private_key_file=~/.ssh/id_ed25519
```
- `debian-01` is a friendly name that matches the OpenTofu key. `ansible_host` is the real address.
- Add `debian-02 ansible_host=192.168.1.209` under `[debian]` ↳ every task now runs on both VMs.

**`ansible/playbook.yml`** (untested)
```yaml
---
- name: Update and harden Debian VMs
  hosts: debian
  become: true

  tasks:
    - name: Apply all available package updates
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
        upgrade: dist

    - name: Ensure admin user is in the sudo group
      ansible.builtin.user:
        name: "{{ ansible_user }}"
        groups: sudo
        append: true

    - name: Harden SSH (no root login, no passwords)
      ansible.builtin.copy:
        dest: /etc/ssh/sshd_config.d/10-hardening.conf
        content: |
          # Managed by Ansible (ansible/playbook.yml). Manual edits will be overwritten.
          PermitRootLogin no
          PasswordAuthentication no
          KbdInteractiveAuthentication no
        owner: root
        group: root
        mode: "0644"
        validate: /usr/sbin/sshd -t -f %s
      notify: Restart SSH

    - name: Ensure qemu-guest-agent is running
      ansible.builtin.service:
        name: qemu-guest-agent
        state: started

    - name: Check whether a reboot is required
      ansible.builtin.stat:
        path: /var/run/reboot-required
      register: reboot_flag

    - name: Reboot if an update asked for it
      ansible.builtin.reboot:
      when: reboot_flag.stat.exists

  handlers:
    - name: Restart SSH
      ansible.builtin.service:
        name: ssh
        state: restarted
```

**What each task does:**

| Task | Module | Key bits |
| --- | --- | --- |
| Updates | `apt` | `upgrade: dist` = `apt dist-upgrade`. `cache_valid_time: 3600` skips `apt update` if it ran in the last hour |
| sudo | `user` | `append: true` adds the group. Without it, `sudo` would replace all other groups |
| SSH hardening | `copy` | Writes a drop-in file. `validate` runs `sshd -t` first. `notify` restarts SSH only if the file changed |
| Guest agent | `service` | `state: started` means "be running", not "run start" |
| Reboot check | `stat` + `register` | Saves whether `/var/run/reboot-required` exists |
| Reboot | `reboot` + `when` | Runs only if the flag exists. Waits for SSH to come back |
| Handler | `service` | Runs once at the end, only if notified. On Debian the service is `ssh`, not `sshd` |

### 3. Run it twice

`--check --diff` ➔ `run 1` ➔ `run 2` ➔ `verify`

1. **Dry run** (like `tofu plan`): `cd ansible && ansible-playbook playbook.yml --check --diff`
2. **Run 1**: `ansible-playbook playbook.yml`
3. **Run 2**: the same command again. The goal is `changed=0`.
4. **Verify**: `ssh root@192.168.1.201` should be refused.

**Predicted results** (from today's VM state):

| Task | Run 1 | Run 2 |
| --- | --- | --- |
| Gathering Facts | ok | ok |
| Updates | ok or changed | ok |
| sudo group | ok (cloud-init did it) | ok |
| Harden SSH | **changed** (new file) | ok |
| Guest agent | ok | ok |
| Reboot check | ok | ok |
| Reboot | skipping, unless updates set the flag | skipping |
| Handler: Restart SSH | **changed** | not run |

**Reading the recap:** `debian-01 : ok=7 changed=0 ... failed=0` on run 2 **is the proof** of idempotency. Anything still `changed` on run 2 is a bug in that task.

## Gotchas
- **sshd uses the first value it reads.** Drop-ins load alphabetically, so `10-hardening.conf` beats cloud-init's `50-cloud-init.conf`.
- **Don't edit `/etc/ssh/sshd_config` directly.** Debian `Include`s `sshd_config.d/*.conf`. Drop-ins survive package upgrades.
- **No `enabled: true` for `qemu-guest-agent`.** On Debian it starts when Proxmox's virtual device appears, and its unit has no install section. Asking to enable it fails.
- **cloud-init only runs on first boot.** Editing the user-data template doesn't touch existing VMs. Ansible does.
- **Changing SSH can lock you out.** Keep one SSH session open while testing in another terminal. If you're locked out: `ssh proxmox-lab`, then `qm terminal 201` (exit with `Ctrl+O`).

## Where does a change belong?
- **Needed before SSH works?** (user, key, IP)
  - ↳ cloud-init
- **Virtual hardware?** (CPU, RAM, disk, NIC)
  - ↳ OpenTofu
- **Inside the running OS?** (packages, config, services, hardening)
  - **Slow to install and identical everywhere?**
    - ↳ bake it into Packer
  - **Otherwise**
    - ↳ Ansible

## Next
- Replace the placeholder `just ansible` recipe with a one-liner that runs the playbook.
- Add `debian-02` to the inventory, then configure both VMs with one command.
- Split into roles once the playbook passes ~15 tasks.
- Use `--check --diff` as a **drift detector**: any reported change means someone edited the VM by hand.
