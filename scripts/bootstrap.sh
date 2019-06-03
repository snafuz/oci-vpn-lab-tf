#!/bin/bash

function setup_firewall(){
    setenforce 0
    firewall-cmd --zone=public --add-port=500/udp --permanent
    firewall-cmd --zone=public --add-port=4500/udp --permanent
    firewall-cmd --zone=public --add-port=4500/tcp --permanent
    firewall-cmd --zone=public --permanent --add-rich-rule='rule protocol value="esp" accept'
    firewall-cmd --zone=public --permanent --add-rich-rule='rule protocol value="ah" accept'
    firewall-cmd --permanent --add-service="ipsec"
    firewall-cmd --zone=public --permanent --add-masquerade
    firewall-cmd --reload
    tee -a /etc/sysctl.conf << END
net.ipv4.ip_forward=1
net.ipv4.conf.default.rp_filter=0
END
    sysctl -p
    setenforce 1
}

setup_firewall

yum -y install libreswan

tee /etc/ipsec.d/oci-ipsec.conf << END
conn oracle-tunnel-1
    left=__ip_address_tunnel_1__
    right=__libreswan_instance_private_ip__
    rightid=__libreswan_instance_public_ip__ 
    authby=secret
    leftsubnet=0.0.0.0/0
    rightsubnet=0.0.0.0/0
    auto=start
    mark=5/0xffffffff
    vti-interface=vti1
    vti-routing=no
    encapsulation=no
    keyexchange=ike
    ikev2=no
    ike=aes_cbc256-sha1;modp1536
    phase2=esp
    phase2alg=aes_cbc256-sha1;modp1536
    pfs=yes
    salifetime=3600s
    sareftrack=no
    nat-ikev1-method=none
conn oracle-tunnel-2
    left=__ip_address_tunnel_2__
    right=__libreswan_instance_private_ip__
    rightid=__libreswan_instance_public_ip__ 
    authby=secret
    leftsubnet=0.0.0.0/0
    rightsubnet=0.0.0.0/0
    auto=start
    mark=6/0xffffffff
    vti-interface=vti2
    vti-routing=no
    encapsulation=no
    keyexchange=ike
    ikev2=no
    ike=aes_cbc256-sha1;modp1536
    phase2=esp
    phase2alg=aes_cbc256-sha1;modp1536
    pfs=yes
    salifetime=3600s
    sareftrack=no
    nat-ikev1-method=none
END

tee /etc/ipsec.d/oci-ipsec.secrets << END 
__ip_address_tunnel_1__ __libreswan_instance_public_ip__: PSK "__psk1__"
__ip_address_tunnel_2__ __libreswan_instance_public_ip__: PSK "__psk2__"
END

