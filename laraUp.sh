#!/bin/bash

# Function to Check if the dependencies are satisfied
# Unsatisfied dependencies will terminate the script with further information
function dependency_check {
	if [[  -z "$(which $1)"  ]]; then
		echo -e "Unmet Dependency, please install the latest $1 from $2 \n"
		exit
	else
		echo -e "$1 is available"
	fi
}

dependency_check "virtualbox" "https://www.virtualbox.org/wiki/Downloads"
dependency_check "vagrant" "http://www.vagrantup.com/downloads"
dependency_check "git" "http://git-scm.com/downloads"

# If Ruby is not installed then install the latest stable rvm
if [[ -z "$(which ruby)" ]]; then
	\curl -sSL https://get.rvm.io | bash -s stable
fi

echo -e "\n All Dependencies met \n"

echo -e "Name of your new Laravel Project" 
read project_name

# Place to install the project locally
project_location="$(pwd)/$project_name"

# The project is created in local environment which can be accessed via virtual machine
composer create-project laravel/laravel $project_name
chmod 777 -R $project_name

# Create a separate folder to hold virtualbox image, separate than project
if [ ! -d  "$(pwd)/vagrant_vbox"  ]; then
    mkdir "$(pwd)/vagrant_vbox"
fi

# virtualbox image name = The project name + timestamp when the script begins
vagrant_dir="$(pwd)/vagrant_vbox/$project_name-$(date +%s)"
mkdir $vagrant_dir

# Making a Vagrantfile with relevant informations, ost notably the project share path
cat <<EOF > $vagrant_dir/Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian-wheezy72-x64-vbox43"
  config.vm.box_url = "http://box.puphpet.com/debian-wheezy72-x64-vbox43.box"
  config.vm.network :forwarded_port, guest: 80, host: 8088
  config.vm.network :private_network, ip: "192.168.56.107"
  config.vm.synced_folder "$vagrant_dir", "/home/vagrant/vagrant"
  config.vm.synced_folder "$project_location", "/home/vagrant/websites/$project_name"
  config.vm.provision :shell, :path => "lara_set.sh"
   config.vm.provider :virtualbox do |vb|
     vb.customize ["modifyvm", :id, "--memory", "512"]
   end
end
EOF

# Setting up Nginx configuration
cat <<EOF > $vagrant_dir/nginx_conf
server {
	listen 80;

	server_name localhost;

	############################
	# The folder root is important to change
	# don't just put the root as your project root
	# but give the public folder as your project root
	# The routing in Laravel is classic, 
	# so, every output in the browser should be via the public folder
	##################################
	root /home/vagrant/websites/$project_name/public; 

	index index.php index.html index.htm;

	access_log /var/log/nginx/$project_name-access.log;
	error_log /var/log/nginx/$project_name-error.log;

	client_max_body_size 25M; 
	default_type text/html;
	charset utf-8;

	location / {
		try_files \$uri \$uri/ @laravel;
		expires 30d;
	}

	location @laravel {
		rewrite ^ /index.php?/\$request_uri;
	}

	location ~ \\.php$ {
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_pass unix:/tmp/php5-fpm.sock;
	}

	location ~* ^/(bootstrap|app|vendor) {
		return 403;
	}

	error_page 404	/index.php;

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	location ~ /\\.ht {
		deny all;
	}

	## Static file handling.
        location ~* .+\.(?:css|gif|htc|js|jpe?g|png|swf)$ {
            expires max;
            ## No need to bleed constant updates. Send the all shebang in one
            ## fell swoop.
            tcp_nodelay off;
            ## Set the OS file cache.
            open_file_cache max=100 inactive=120s;
            open_file_cache_valid 45s;
            open_file_cache_min_uses 2;
            open_file_cache_errors off;
        }

	location = /favicon.ico {
        try_files /favicon.ico =204;
    }

}
EOF

# Bash script to run after OS Image is installed in virtual machine
cat <<EOF > $vagrant_dir/lara_set.sh
#!/bin/bash

sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password toor'
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password toor'
sudo apt-get update
sudo apt-get -y install mysql-server-5.5 php5-mysql nginx php5 git-core
sudo apt-get -y install php5-common php5-ldap php5-cli php5-intl php5-mcrypt php5-curl php5-fpm php5-gd php5-imagick php5-memcached php5-memcache php5-xmlrpc php5-xsl php5-geoip

cd /home/vagrant
sudo chmod 777 -R websites
git clone https://github.com/rajibmp/laravel-nginx.git nginx-laravel
sudo rm -rf /etc/nginx/*
sudo cp -R nginx-laravel/nginx/* /etc/nginx/ 
sudo cp -R nginx-laravel/php-fpm/* /etc/php5/fpm/pool.d/
sudo cp /home/vagrant/vagrant/nginx_conf  /etc/nginx/sites-available/laravel
sudo rm /etc/nginx/sites-enabled/*
sudo ln -s /etc/nginx/sites-available/* /etc/nginx/sites-enabled/
sudo mkdir /var/cache/nginx
sudo service apache2 stop
sudo service mysql restart
sudo service php5-fpm restart
sudo service nginx restart
EOF

cd $vagrant_dir
vagrant up
vagrant ssh
