#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y docker
sudo yum install -y httpd
echo "<html><h1>My first webserver spinned using terraform for ec2</h1></html>"
/var/www/html/index.html
sudo service httpd start
chkconfig httpd on
sudo service docker start
sudo usermod -a -G docker ec2-user
chkconfig docker on