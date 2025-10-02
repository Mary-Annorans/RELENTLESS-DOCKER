output "jenkins_server_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

output "portfolio_url" {
  description = "Portfolio website URL"
  value       = "http://${aws_instance.jenkins_server.public_ip}"
}

output "ssh_connection" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i Datadog-kp.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
}

output "jenkins_initial_password_command" {
  description = "Command to get Jenkins initial admin password"
  value       = "ssh -i Datadog-kp.pem ubuntu@${aws_instance.jenkins_server.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}
