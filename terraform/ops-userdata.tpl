#cloud-config

package_update: true

package_upgrade: true

packages:
 - awscli
 - curl
 - git
 - build-essential

bootcmd:
 - echo 127.0.1.1 ${hostname}.${domainname} ${hostname} >> /etc/hosts
 - hostname ${hostname}.${domainname}

preserve_hostname: true

runcmd:
 - curl -s https://packagecloud.io/install/repositories/chef/stable/script.deb.sh | sudo bash
 - apt-get -y -qq install chefdk
 - mkdir /var/chef-solo
 - chown ubuntu /var/chef-solo
 - cd /var/chef-solo
 - sudo -u ubuntu git clone https://github.com/darrin-wortlehock/devops-demo.git
 - cd devops-demo
 - sudo -u ubuntu berks vendor cookbooks
 - chef-solo -c solo/solo.rb -j solo/ops.json
 - until aws s3 ls s3://${secrets_bucket} --region=${aws_region} | grep -q "devops-demo-validator.pem"; do echo "waiting for s3://${secrets_bucket}/devops-demo-validator.pem ..."; sleep 10; done;
 - aws s3 cp s3://${secrets_bucket}/devops-demo-validator.pem /etc/chef/validation.pem --region=${aws_region}
 - chef-client
 - echo "Finished."
