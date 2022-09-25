//create 3 ec2 instances

resource "aws_instance" "instance" {
  count                = length(aws_subnet.public_subnet.*.id)
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = element(aws_subnet.public_subnet.*.id, count.index)
  security_groups      = [aws_security_group.sg.id, ]
  key_name             = "Keypair-01"
  iam_instance_profile = data.aws_iam_role.iam_role.name

  tags = {
    "Name"        = "Instance-${count.index}"
    "Environment" = "Test"
    "CreatedBy"   = "Terraform"
  }

  timeouts {
    create = "10m"
  }

}

resource "null_resource" "null" {
  count = length(aws_subnet.public_subnet.*.id)

  provisioner "file" {
    source      = "./userdata.sh"
    destination = "/home/ec2-user/userdata.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/userdata.sh",
      "sh /home/ec2-user/userdata.sh",
    ]
    on_failure = continue
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    port        = "22"
    host        = element(aws_eip.eip.*.public_ip, count.index)
    private_key = file(var.ssh_pr_key)
  }

}

// create 3 elastic ips

resource "aws_eip" "eip" {
  count            = length(aws_instance.instance.*.id)
  instance         = element(aws_instance.instance.*.id, count.index)
  public_ipv4_pool = "amazon"
  vpc              = true

  tags = {
    "Name" = "EIP-${count.index}"
  }
}


// create eip association with ec2 instances

resource "aws_eip_association" "eip_assoc" {
  count         = length(aws_eip.eip)
  instance_id   = element(aws_instance.instance.*.id, count.index)
  allocation_id = element(aws_eip.eip.*.id, count.index)

}




