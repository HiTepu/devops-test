sudo su
exit
ip addr show
exit
ssh dev@100.118.219.186
ping 100.118.219.186
exit
ip addr shwo
ip addr show
netbird up
ping 192.168.1.22
ping 192.168.1.18
SERVERS=(192.168.1.67 192.168.1.22 192.168.1.51 192.168.1.110 192.168.1.109 192.168.1.52); for ip in "${SERVERS[@]}"; do   echo "==> $ip";   && echo "OK $ip" || echo "FAILED $ip"; \
done
SERVERS=(192.168.1.67 192.168.1.22 192.168.1.51 192.168.1.110 192.168.1.109 192.168.1.52); for ip in "${SERVERS[@]}"; do   echo "==> $ip";   sshpass -p 'Admin@123' ssh -o StrictHostKeyChecking=no dev@"$ip" "sudo useradd -m -s /bin/bash MinhPA || true; echo 'MinhPA:ChangeMe\!2025' | sudo chpasswd; sudo chage -d 0 MinhPA; sudo mkdir -p /home/MinhPA/.ssh; sudo chmod 700 /home/MinhPA/.ssh; sudo chown -R MinhPA:MinhPA /home/MinhPA/.ssh; echo 'done on $ip'"   && echo "OK $ip" || echo "FAILED $ip"; done
ssh MinhPA@192.168.1.67
ping 100.118.203.160
ip a
ping 100.118.203.160
ping 192.168.1.110
ping 100.118.203.160
clear
ping 100.118.203.160
exit
sudo su
ls
cd ..
dc ..
ls
cd ..
ls
cd ..
ls
cd var
ls
sudo adduser username
sudo adduser hienvd
sudo usermod -aG sudo hienvd
groups hienvd
su - hienvd
sudo adduser MinhPA
sudo adduser minhpa
exit
sudo adduser bosshwng
exit
netbird status
netbird up
netbird down
i
netbird up
ip a
vi /etc/netplan/50-cloud-init.yaml 
sudo vi
clear
sudo su
ls
sudo .home
cd home
cd /home
ls
ls -a
cd ..
ls
cd tmp/
tar -xvf k8s-offline.tar
chmod +x kubeadm kubelet kubectl
sudo mv kubeadm kubelet kubectl /usr/local/bin/
cd ..
sudo tee /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/
After=network.target

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet
sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet
kubectl apply -f calico/tigera-operator.yaml
kubectl apply -f calico/custom-resources.yaml
sudo kubeadm init   --pod-network-cidr=192.168.0.0/16   --apiserver-advertise-address=192.168.1.68
cd tmp
kubectl apply -f tigera-operator.yaml
kubectl apply -f custom-resources.yaml
ls
cd calico/
kubectl apply -f tigera-operator.yaml
kubectl apply -f custom-resources.yaml
ls
ls -a
cd ..
ls
ls -a
kubectl apply -f calico/tigera-operator.yaml
kubectl apply -f calico/custom-resources.yaml
cd cal
cd calico/
tar -xvf k8s-offline.tar
ls
tar -xvf k8s-offline.tar -C .
ls
tar -xvf k8s-offline.tar -C .
sudo mkdir -p /opt/k8s
sudo tar -xvf /tmp/k8s-offline.tar -C /opt/k8s
cd /opt/k8s
kubectl apply -f calico/tigera-operator.yaml
kubectl apply -f calico/custom-resources.yaml
cd /opt/k8s
ls -R
sudo mkdir -p /opt/k8s/calico-yamls
sudo tar -xvf /opt/k8s/calico/k8s-offline.tar -C /opt/k8s/calico-yamls
ls /opt/k8s/calico-yamls
ufw disable
sudo su
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/confi
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo su
SUDO SU
sudo su
