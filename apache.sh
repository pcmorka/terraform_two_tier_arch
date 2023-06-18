#shell script to bootstrap EC2 instances
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>This is Terraform CI/CD Deployment. $(hostname -f)</h1>" > /var/www/html/index.html