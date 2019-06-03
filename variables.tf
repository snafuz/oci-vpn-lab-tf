variable  "region"{
    default = "iad"
}

variable "cloud-vcn-cidr" {
    default =  "10.0.0.0/16"
}
variable "onprem-vcn-cidr" {
    default = "172.16.0.0/16"
}
variable "cloud-sub-cidr"{
    default = "10.0.1.0/24"
}

variable "onprem-dmz-sub-cidr"{
    default = "172.16.0.0/24"
}

variable "onprem-secure-sub-cidr"{
    default = "172.16.1.0/24"
}

variable "libreswan-secondary-private-ip"{
    default = "172.16.0.200"
}

variable "libreswan-shape"{
    default = "VM.Standard2.1"
}
variable "cloud-instance-shape"{
    default = "VM.Standard2.1"
}
variable "bootstrapfile" {
  default = "./scripts/bootstrap.sh"
}

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}

variable "regions-map"{
    type = "map"
    default = {
        yyz = "ca-toronto-1"
        fra = "eu-frankfurt-1"
        lon = "uk-london-1"
        iad = "us-ashburn-1"
        phx  = "us-phoenix-1"
    }
}

variable "ol7-image" {
  type = "map"

  default = {
    // See https://docs.us-phoenix-1.oraclecloud.com/images/
    // Oracle-provided image "Oracle-Linux-7.6-2019.03.22-1"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaaqopv4wgbh54jrqoa4bjpkng2y2npzoe2jaj5pdne37ljdxbbbdka"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa2n5z4nmkqjf27btkbdibflwvximz5i3rsz57c3gowckozrdshnua"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaaaxnnrqke453ur5katouvfn2i6oweuwpixx6mm5e4nqtci7oztx5a"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaavxqdkuyamlnrdo3q7qa7q3tsd6vnyrxjy3nmdbpv7fs7um53zh5q"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaapxvrtwbpgy3lchk2usn462ekarljwg4zou2acmundxlkzdty4bjq"
  }
}

variable "centos7-image" {
  type = "map"

  default = {
    // See https://docs.us-phoenix-1.oraclecloud.com/images/
    // Oracle-provided image "CentOS-7-2019.03.08-0"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaaqqbtppujg46m2twxeam2god3ktu5s6ehamexb66wsb4ll4vaxpfq"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaavsw2452x5psvj7lzp7opjcpj3yx7or4swwzl5vrdydxtfv33sbmq"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaa3iltzfhdk5m6f27wcuw4ttcfln54twkj66rsbn52yemg3gi5pkqa"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaahhgvnnprjhfmzynecw2lqkwhztgibz5tcs3x4d5rxmbqcmesyqta"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaaa2ph5vy4u7vktmf3c6zemhlncxkomvay2afrbw5vouptfbydwmtq"
  }
}
