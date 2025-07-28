yum update -y


dnf install -y java-21-amazon-corretto wget


wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key


yum install -y jenkins


systemctl enable jenkins
systemctl start jenkins


echo "Initial Jenkins Unlock Key:"
cat /var/lib/jenkins/secrets/initialAdminPassword
