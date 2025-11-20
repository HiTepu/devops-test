#!/bin/bash

# Backup config cũ
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup

# Thêm harbor registry config
sudo tee -a /etc/containerd/config.toml > /dev/null <<EOF

# Harbor Registry Configuration
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.1.243"]
      endpoint = ["http://192.168.1.243"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.local"]
      endpoint = ["http://harbor.local"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.1.243".tls]
      insecure_skip_verify = true
    [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.local".tls]
      insecure_skip_verify = true
EOF

# Restart containerd
sudo systemctl restart containerd

# Verify
echo "Containerd status:"
sudo systemctl status containerd --no-pager | head -n 5

echo "Configuration completed on $(hostname)"
