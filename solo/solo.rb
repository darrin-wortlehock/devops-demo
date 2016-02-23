file_cache_path "/var/chef-solo"
cookbook_path ["/var/chef-solo/devops-demo/cookbooks","/var/chef-solo/devops-demo/site-cookbooks"]
role_path "/var/chef-solo/devops-demo/roles"
data_bag_path "/var/chef-solo/devops-demo/data-bags"

# Recommended to protect against man-in-the-middle attacks
ssl_verify_mode :verify_peer