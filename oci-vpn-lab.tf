



provider "oci" {
    alias            = "vpnlab"
    tenancy_ocid     = "${var.tenancy_ocid}"
    user_ocid        = "${var.user_ocid}"
    fingerprint      = "${var.fingerprint}"
    private_key_path = "${var.private_key_path}"
    region           =  "${lookup(var.regions-map, var.region)}"
}


resource "oci_core_drg" "cloud-drg" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    display_name = "cloud.drg"
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}

resource "oci_core_vcn" "cloud-vcn" {
    provider       = "oci.vpnlab"
    cidr_block     = "${var.cloud-vcn-cidr}"
    dns_label      = "cloudvcn"
    compartment_id = "${var.compartment_ocid}"
    display_name   = "cloud.vcn"
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}


resource "oci_core_vcn" "onprem-vcn" {
    provider       = "oci.vpnlab"
    cidr_block     = "${var.onprem-vcn-cidr}"
    dns_label      = "onpremvcn"
    compartment_id = "${var.compartment_ocid}"
    display_name   = "onprem.vcn"
    freeform_tags = [{"lab"= "network"},{"vpn"="onprem"}]
}

resource "oci_core_internet_gateway" "cloud-igw" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_vcn.cloud-vcn.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
    display_name = "cloud.igw"
}

resource "oci_core_route_table" "cloud-rt" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_vcn.cloud-vcn.id}"
    display_name = "cloud.rt"
    route_rules =[ {
        destination = "${var.onprem-vcn-cidr}"
        network_entity_id = "${oci_core_drg.cloud-drg.id}"
    },
    {
        destination = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.cloud-igw.id}"
    },
    ]
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}

resource "oci_core_security_list" "cloud-sl" {
    provider       = "oci.vpnlab"
    display_name   = "cloud-sl"
    compartment_id = "${var.compartment_ocid}"
    vcn_id         = "${oci_core_vcn.cloud-vcn.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"= "cloud"}]

    egress_security_rules = [{
        protocol    = "all"
        destination = "0.0.0.0/0"
    }]

    ingress_security_rules = [{
        tcp_options {
            "max" = 22
            "min" = 22
        }

        protocol = "6"
        source   = "0.0.0.0/0"
    },
    {
        protocol = 1
        source   = "${var.onprem-vcn-cidr}"
    },
    ]
}


resource "oci_core_drg_attachment" "cloud-drg-att" {
    provider       = "oci.vpnlab"
    drg_id     = "${oci_core_drg.cloud-drg.id}"
    vcn_id     = "${oci_core_vcn.cloud-vcn.id}"
}

resource "oci_core_subnet" "cloud-sub" {
    provider       = "oci.vpnlab"
    cidr_block        = "${var.cloud-sub-cidr}"
    display_name      = "cloud.sub"
    dns_label         = "cloudsub"
    compartment_id    = "${var.compartment_ocid}"
    vcn_id            = "${oci_core_vcn.cloud-vcn.id}"
    security_list_ids =[ "${oci_core_security_list.cloud-sl.id}"]
    route_table_id    = "${oci_core_route_table.cloud-rt.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}

resource "oci_core_cpe" "cloud-cpe" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    ip_address = "${oci_core_instance.libreswan-instance.public_ip}"
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}

resource "oci_core_ipsec" "cloud-ipsec-connection" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    cpe_id = "${oci_core_cpe.cloud-cpe.id}"
    drg_id = "${oci_core_drg.cloud-drg.id}"
    static_routes = ["0.0.0.0/0"]
    display_name = "cloud.vpn"
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}



resource "oci_core_internet_gateway" "onprem-igw" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_vcn.onprem-vcn.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
    display_name = "onprem.igw"
}

resource "oci_core_route_table" "onprem-dmz-rt" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_vcn.onprem-vcn.id}"
    display_name = "onprem.dmz-rt"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
    route_rules = [{
        destination = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.onprem-igw.id}"
    }]
}

resource "oci_core_route_table" "onprem-secure-rt" {
    provider       = "oci.vpnlab"
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_vcn.onprem-vcn.id}"
    display_name = "onprem.secure-rt"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
    route_rules = [{
        destination = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.onprem-igw.id}"
    },
    {
        destination = "${var.cloud-vcn-cidr}"
        network_entity_id = "${lookup(data.oci_core_private_ips.libreswan-private-ip-ds.private_ips[0],"id")}"
    }]
}


resource "oci_core_security_list" "onprem-dmz-sl" {
    provider       = "oci.vpnlab"
    display_name   = "onprem-dmz-sl"
    compartment_id = "${var.compartment_ocid}"
    vcn_id         = "${oci_core_vcn.onprem-vcn.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]

    egress_security_rules = [{
        protocol    = "all"
        destination = "0.0.0.0/0"
    }]

    ingress_security_rules = [{
        tcp_options {
            "max" = 22
            "min" = 22
        }

        protocol = "6"
        source   = "0.0.0.0/0"
    },
    {
        protocol = 1
        source   = "${var.cloud-vcn-cidr}"
    },
    {
        protocol = 1
        source   = "${var.onprem-dmz-sub-cidr}"
    },
    {
        protocol = 50
        source   = "0.0.0.0/0"
    },
    ]
}



resource "oci_core_subnet" "onprem-dmz-sub" {
    provider       = "oci.vpnlab"
    cidr_block        = "${var.onprem-dmz-sub-cidr}"
    display_name      = "onprem.dmz"
    dns_label         = "onpremdmz"
    compartment_id    = "${var.compartment_ocid}"
    vcn_id            = "${oci_core_vcn.onprem-vcn.id}"
    security_list_ids   = ["${oci_core_security_list.onprem-dmz-sl.id}"]
    route_table_id    = "${oci_core_route_table.onprem-dmz-rt.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
}

resource "oci_core_subnet" "onprem-secure-sub" {
    provider       = "oci.vpnlab"
    cidr_block        = "${var.onprem-secure-sub-cidr}"
    display_name      = "onprem.secure"
    dns_label         = "onpremsecure"
    compartment_id    = "${var.compartment_ocid}"
    vcn_id            = "${oci_core_vcn.onprem-vcn.id}"
    route_table_id    = "${oci_core_route_table.onprem-secure-rt.id}"
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
}



data "oci_identity_availability_domain" "ad" {
    provider = "oci.vpnlab"
    compartment_id = "${var.tenancy_ocid}"
    ad_number      = 1
}


resource "oci_core_instance" "libreswan-instance" {
    provider = "oci.vpnlab"
    availability_domain = "${data.oci_identity_availability_domain.ad.name}"
    compartment_id      = "${var.compartment_ocid}"
    shape = "${var.libreswan-shape}"

    create_vnic_details {
        subnet_id = "${oci_core_subnet.onprem-dmz-sub.id}"
        skip_source_dest_check = "true"
    }
    display_name = "libreswan"
    hostname_label = "libreswan"
    metadata {
        ssh_authorized_keys = "${var.ssh_public_key}"
        user_data = "${base64encode(file(var.bootstrapfile))}"
    }
    source_details {
        source_id   = "${var.centos7-image[lookup(var.regions-map, var.region)]}"
        source_type = "image"
    }
    preserve_boot_volume = false
    freeform_tags = [{"lab"= "network"},{"vpn"= "onprem"}]
}

resource "oci_core_instance" "cloud-instance" {
    provider = "oci.vpnlab"
    availability_domain = "${data.oci_identity_availability_domain.ad.name}"
    compartment_id      = "${var.compartment_ocid}"
    shape = "${var.cloud-instance-shape}"

    create_vnic_details {
        subnet_id = "${oci_core_subnet.cloud-sub.id}"
    }
    display_name = "cloud.instance"
    hostname_label = "cloudinstance"
    metadata {
        ssh_authorized_keys = "${var.ssh_public_key}"
    }
    source_details {
        source_id   = "${var.ol7-image[lookup(var.regions-map, var.region)]}"
        source_type = "image"
    }
    preserve_boot_volume = false
    freeform_tags = [{"lab"= "network"},{"vpn"="cloud"}]
}


data "oci_core_vnic_attachments" "libreswan-vnic-att-ds" {
    provider = "oci.vpnlab"
    compartment_id      = "${var.compartment_ocid}"
    instance_id         = "${oci_core_instance.libreswan-instance.id}"
}

# Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "libreswan-vnic-ds" {
    provider = "oci.vpnlab"
    vnic_id = "${lookup(data.oci_core_vnic_attachments.libreswan-vnic-att-ds.vnic_attachments[0],"vnic_id")}"
}

# List Private IPs
data "oci_core_private_ips" "libreswan-private-ip-ds" {
    provider = "oci.vpnlab"
    vnic_id    = "${data.oci_core_vnic.libreswan-vnic-ds.id}"
}


resource "null_resource" "update-ips" {
  triggers {
    libreswan-instance-ids = "${join(",", oci_core_ipsec.cloud-ipsec-connection.*.id)}"
  }
  
   provisioner "local-exec" {
    command = "sleep 9"
  }

    provisioner "remote-exec" {
    connection {
        agent       = false
        timeout     = "10m"
        host        = "${oci_core_instance.libreswan-instance.public_ip}"
        user        = "opc"
        private_key = "${var.ssh_private_key}"
    }

    inline = [
        "sudo service ipsec stop",
        "sudo sed -i 's/__libreswan_instance_private_ip__/${oci_core_instance.libreswan-instance.private_ip}/g' /etc/ipsec.d/oci-ipsec.conf",
        "sudo sed -i 's/__libreswan_instance_public_ip__/${oci_core_instance.libreswan-instance.public_ip}/g' /etc/ipsec.d/oci-ipsec.conf",
        "sudo sed -i 's/__ip_address_tunnel_1__/${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[0],"ip_address")}/g' /etc/ipsec.d/oci-ipsec.conf",
        "sudo sed -i 's/__ip_address_tunnel_2__/${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[1],"ip_address")}/g' /etc/ipsec.d/oci-ipsec.conf",
        "sudo sed -i 's/__libreswan_instance_public_ip__/${oci_core_instance.libreswan-instance.public_ip}/g' /etc/ipsec.d/oci-ipsec.secrets",
        "sudo sed -i 's/__ip_address_tunnel_1__/${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[0],"ip_address")}/g' /etc/ipsec.d/oci-ipsec.secrets",
        "sudo sed -i 's/__ip_address_tunnel_2__/${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[1],"ip_address")}/g' /etc/ipsec.d/oci-ipsec.secrets",
        "sudo sed -i 's/__psk1__/${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[0],"shared_secret")}/g' /etc/ipsec.d/oci-ipsec.secrets",
        "sudo sed -i 's/__psk2__/${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[1],"shared_secret")}/g' /etc/ipsec.d/oci-ipsec.secrets",
        "sudo service ipsec start",
        "sleep 7",
        "sudo ip route add ${var.cloud-vcn-cidr} nexthop dev vti1 nexthop dev vti2",
        ]
  }

}

output "libreswan_ips" {
  value = [
      "${oci_core_instance.libreswan-instance.private_ip}",
      "${oci_core_instance.libreswan-instance.public_ip}"
      ]
}
output "cloud-instance_ips" {
  value = [
      "${oci_core_instance.cloud-instance.private_ip}",
      "${oci_core_instance.cloud-instance.public_ip}"
      ]
}

data "oci_core_ipsec_config" "cloud-ipsec-config" {
    ipsec_id = "${oci_core_ipsec.cloud-ipsec-connection.id}"
  
}

output "tunnel-1" {
    value = [
        "${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[0],"ip_address")}",    
        "${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[0],"shared_secret")}"
    ]
}

output "tunnel-2" {
    value = [
        "${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[1],"ip_address")}",
        "${lookup(data.oci_core_ipsec_config.cloud-ipsec-config.tunnels[1],"shared_secret")}"
    ]
}

