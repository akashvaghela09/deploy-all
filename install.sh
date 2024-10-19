#!/bin/bash

# Function to install Nginx
install_nginx() {
  echo "Installing Nginx..."
  apt update && apt install -y nginx

  if [ $? -ne 0 ]; then
    echo "Failed to install Nginx."
    exit 1
  else
    echo "Nginx installed successfully."
    systemctl status nginx
  fi
}

# Function to install Docker
install_docker() {
  echo "Installing Docker..."
  snap install docker

  if [ $? -ne 0 ]; then
    echo "Failed to install Docker."
    exit 1
  else
    echo "Docker installed successfully."
  fi
}

# Function to generate Nginx configuration
generate_nginx_conf() {
  local domain_name="$1"
  local nginx_conf_path="/etc/nginx/sites-available/$domain_name"
  local locations=""

  while true; do
    read -p "Enter the repo/path name (or type 'done' to finish): " repo_name
    if [[ "$repo_name" == "done" ]]; then
      break
    fi

    read -p "Enter the port for $repo_name: " port
    locations+=$(cat <<EOF
    location /$repo_name/ {
        proxy_pass http://localhost:$port/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

EOF
)
  done

  # Create Nginx configuration file
  {
    echo "server {"
    echo "    listen 80;"
    echo "    server_name $domain_name;"
    echo ""
    echo "$locations"
    echo "}"
  } | sudo tee "$nginx_conf_path" > /dev/null

  # Check if the sites-enabled directory exists
  if [ ! -d "/etc/nginx/sites-enabled/" ]; then
    echo "Creating sites-enabled directory..."
    sudo mkdir -p /etc/nginx/sites-enabled/
  fi

  # Create a symlink to enable the site
  sudo ln -sf "$nginx_conf_path" /etc/nginx/sites-enabled/

  # Test Nginx configuration
  if ! nginx -t; then
    echo "Nginx configuration test failed."
    exit 1
  fi

  # Reload Nginx
  sudo systemctl reload nginx
  echo "Nginx reloaded with new configuration."
}

# Function to add a new server
add_new_server() {
  local domain_name
  read -p "Enter the current domain name: " domain_name
  generate_nginx_conf "$domain_name"
  echo "New server added successfully."
}

# Function to update the domain
update_domain() {
  local old_domain
  local new_domain
  read -p "Enter the current domain name: " old_domain
  read -p "Enter the new domain name: " new_domain

  sudo sed -i "s/$old_domain/$new_domain/g" /etc/nginx/sites-available/$old_domain
  sudo mv "/etc/nginx/sites-available/$old_domain" "/etc/nginx/sites-available/$new_domain"
  sudo mv "/etc/nginx/sites-enabled/$old_domain" "/etc/nginx/sites-enabled/$new_domain"

  # Test Nginx configuration
  if ! nginx -t; then
    echo "Nginx configuration test failed."
    exit 1
  fi

  # Reload Nginx
  sudo systemctl reload nginx
  echo "Domain updated successfully."
}

# Main Menu Function
main_menu() {
  while true; do
    echo "Select an option:"
    echo "1) New Setup"
    echo "2) Install Nginx"
    echo "3) Install Docker"
    echo "4) Add New Server"
    echo "5) Update Domain"
    echo "6) Exit"

    read -p "Choose an option (1-6): " option

    case $option in
      1)
        # Check if Nginx is installed before proceeding
        if ! command -v nginx &> /dev/null; then
          install_nginx
        fi
        read -p "Enter your project's root domain name (e.g., example.com): " domain_name
        generate_nginx_conf "$domain_name"
        ;;
      2)
        install_nginx
        ;;
      3)
        install_docker
        ;;
      4)
        add_new_server
        ;;
      5)
        update_domain
        ;;
      6)
        echo "Exiting..."
        exit 0
        ;;
      *)
        echo "Invalid option, please choose again."
        ;;
    esac
  done
}

# Run the main menu
main_menu
