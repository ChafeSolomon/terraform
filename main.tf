resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  for_each    = toset(concat([for node in range(1) : "node${node}"],["master"]))
  name        = each.value
  node_name = "proxmox"

  # should be true if qemu agent is not installed / enabled on the VM
  stop_on_destroy = true
  cpu {
    cores        = 2
    type         = "x86-64-v2-AES"  # recommended for modern CPUs
  }
  memory {
    dedicated = each.value == "master" ? 2000:4000
  }
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 50
  }

  initialization {
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }

    ip_config {
      ipv4 {
        # We will have to fix this later
        address = "${lookup(local.ip_mapping, each.key, "192.168.1.100")}/24"
        # address = "dhcp"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
      password = "password"
      username = "proxmox"
  }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge = "vmbr0"
  }

}
resource "proxmox_virtual_environment_vm" "nfs_vm" {
  name        = "NFS"
  node_name = "proxmox"

  # should be true if qemu agent is not installed / enabled on the VM
  stop_on_destroy = true
  # Commented to unmount // will have to uncomment if rebuild
  # cdrom{
  #   file_id = proxmox_virtual_environment_download_file.NAS.id
  # }
  memory {
    dedicated = 2048
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    iothread     = true
    file_format  = "raw"
    discard      = "on"
    size         = 20
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "virtio1"
    iothread     = true
    file_format  = "raw"
    discard      = "on"
    size         = 100
  }

  initialization {
    user_account {
      # do not use this in production, configure your own ssh key instead!
      username = "proxmox"
      password = "password"
    }
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }
  lifecycle {
    prevent_destroy = true
 }
}
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "proxmox"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

resource "proxmox_virtual_environment_download_file" "NAS" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "proxmox"
  url          = "https://sourceforge.net/projects/openmediavault/files/iso/7.4.17/openmediavault_7.4.17-amd64.iso"
  checksum = "ee20ddab3e42b320972cf3446b413ac698b4e5b85d1482ec52c8fdf247ffb28e"
  checksum_algorithm = "sha256"
  lifecycle {
    prevent_destroy = true
 }

}
# Resource for cloud-init features
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "proxmox"

  source_raw {
    data = <<-EOF
      #cloud-config
      chpasswd:
        list: |
          proxmox:password
        expire: false
      packages:
        - qemu-guest-agent
        - ansible
      users:
        - default
        - name: proxmox
          groups: sudo
          shell: /bin/bash
          ssh-authorized-keys:
            - ${trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)}
          sudo: ALL=(ALL) NOPASSWD:ALL
      write_files:
      # not writing to /tmp
      - path: /etc/ansible/inventory
        permissions: "0644"
        content: |
          [master]
          master

          [nodes]
          node0
          node1
          node2
          node3
          node4
      - path: /etc/hosts
        permissions: "0644"
        content: |
          127.0.0.1 localhost

          # The following lines are desirable for IPv6 capable hosts
          ::1 ip6-localhost ip6-loopback
          fe00::0 ip6-localnet
          ff00::0 ip6-mcastprefix
          ff02::1 ip6-allnodes
          ff02::2 ip6-allrouters
          ff02::3 ip6-allhosts

          # k8 nodes
          192.168.1.105 master
          192.168.1.106 node0
          192.168.1.107 node1     
      runcmd:
        - "chown proxmox:proxmox /etc/ansible/inventory"
        - "git clone https://github.com/k3s-io/k3s-ansible.git"
        - "mv k3s-ansible.git /home/proxmox/k3s-ansible.git"
        - "add-apt-repository --yes --update ppa:ansible/ansible"
        - "apt install nfs-common"
            EOF

    file_name = "cloud-config.yaml"
  }
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.ubuntu_vm_key.private_key_openssh
  filename = "id_rsa"
  file_permission = "0400"  # Restrict permissions to read-only for the owner
}