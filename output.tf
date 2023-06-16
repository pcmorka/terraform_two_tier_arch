#Create an output for db-instance endpoint

output "db-instance-endpoint" {
  description = "DB instance endpoint"
  value       = aws_db_instance.wk22project-db-instance.endpoint
}


output "wk22Project-WebServer_public_ips" {
  description = "The public IP addresses of the web server-tier instances"
  value = aws_launch_template.wk22Project-WebServer.public_ip
}