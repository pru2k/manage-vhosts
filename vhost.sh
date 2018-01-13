#!/bin/bash

# Display usage info
vhost-usage() {
cat <<"USAGE"
Usage: vhost [OPTIONS] <name>
    -h|--help   this screen
    -d          The project directory name
    -url        The local address, default is http://name.local
    -rm         Remove a previously created vhost
    -email      Specify the email of the administrator in the virtual host file
    -l          List the current virtual hosts

Examples:
vhost -d mysite.co.uk mysite    Create a project folder called 'mysite.co.uk' with the url of 'http://mysite.local'
vhost mysite                    This will create a vhost named 'mysite' with a webroot of '~/sites/mysite/public_html' reachable at 'http://mysite.local'
vhost -rm mysite.local mysite   Remove the Apache2 vhost named 'mysite'. Doesn't delete the webroot folder.
USAGE
exit 0
}

# Delete a virtual host file, remove its Apache conf file, disable the site and restart Apache
vhost-remove() {
    #sudo -v
    echo "Disabling and deleting the $name virtual host."
    sudo a2dissite $name
    sudo rm /etc/apache2/sites-available/$name
    sudo service apache2 reload
    exit 0
}

vhost-list() {
    echo "Available virtual hosts:"
    ls -l /etc/apache2/sites-available/
    echo "Enabled virtual hosts:"
    ls -l /etc/apache2/sites-enabled/
    exit 0
}

# Define and create default values
name="${!#}"
email="webmaster@localhost"
url="$name.local"
webroot="$HOME/sites/$name/public_html"
projectroot="$HOME/sites/$name"

# Loop to read options and arguments
while [ $1 ]; do
    case "$1" in
        '-l') vhost-list;;
        '-h'|'--help') vhost-usage;;
        '-rm') url="$2"
               vhost-remove;;
        '-d')
            projectroot="$HOME/sites/$2"
            webroot="$HOME/sites/$2/public_html";;
        '-url') url="$2";;
        '-email') email="$2";;
    esac
    shift
done

sudo -v

# Check if the webroot exists
if [ ! -d "$webroot" ]; then
    echo "Creating $webroot directory"
    mkdir -p $webroot
fi

# Create virtual host files
echo "Creating the new $name virtual host file that has a webroot of: $webroot"

# Replace placeholders in the vhost template file
sudo cp ./templates/vhost-template.conf /etc/apache2/sites-available/$name.conf
sudo cp ./templates/sublime-project.template $projectroot/$name.sublime-project
sudo cp ./templates/readme.md.template $projectroot/README.md
sudo sed -i 's/template.email/'$email'/g' /etc/apache2/sites-available/$name.conf
sudo sed -i 's/template.url/'$url'/g' /etc/apache2/sites-available/$name.conf
sudo sed -i 's#template.webroot#'$webroot'#g' /etc/apache2/sites-available/$name.conf

sudo a2ensite $name
sudo service apache2 reload

echo "Virtual host $name created with a webroot of $webroot reachable from http://$url"

exit 0