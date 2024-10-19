#!/bin/bash

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

# Function to install Nginx
install_nginx() {
  echo "Installing Nginx..."
  apt update && apt install -y nginx

  if [ $? -ne 0 ]; then
    echo "Failed to install Nginx."
    exit 1
  else
    echo "Nginx installed successfully."
  fi
}

# Function to configure UFW for Nginx
setup_firewall() {
  echo "Configuring firewall..."
  
  ufw app list

  # Enable UFW with the --force option to bypass confirmation
  ufw --force enable
  ufw allow 'Nginx HTTP'
  ufw status

  if [ $? -ne 0 ]; then
    echo "Failed to configure the firewall."
    exit 1
  else
    echo "Firewall configured successfully."
  fi
}

# Function to prompt for the domain name
ask_domain_name() {
  read -p "Enter your project's root domain name (e.g., example.com): " domain_name

  if [ -z "$domain_name" ]; then
    echo "Domain name cannot be empty."
    exit 1
  fi

  echo "Your project's root domain is: $domain_name"
  echo "$domain_name"  # Return the domain name
}

# Function to generate the Nginx configuration file
generate_nginx_conf() {
  local domain_name=$1
  local nginx_conf_path="/etc/nginx/sites-available/$domain_name"

  echo "Generating Nginx configuration file at $nginx_conf_path..."

  # Start building the Nginx configuration
  {
    echo "server {"
    echo "    listen 80;"
    echo "    server_name $domain_name;"

    # Read the docker-compose.yml file to get services and ports
    services=$(yq '.services | keys' docker-compose.yml | tr -d '[]," ')

    for service in $services; do
      port=$(yq ".services.$service.ports[0]" docker-compose.yml | cut -d ':' -f 1 | tr -d ' ')

      echo ""
      echo "    location /$service/ {"
      echo "        proxy_pass http://localhost:$port/;"
      echo "        proxy_set_header Host \$host;"
      echo "        proxy_set_header X-Real-IP \$remote_addr;"
      echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
      echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
      echo "    }"
    done

    echo "}"
  } | sudo tee "$nginx_conf_path" > /dev/null

  if [ $? -ne 0 ]; then
    echo "Failed to create Nginx configuration file."
    exit 1
  else
    echo "Nginx configuration file created successfully."
  fi

  # Create a symlink to enable the site
  sudo ln -s "$nginx_conf_path" /etc/nginx/sites-enabled/

  # Test Nginx configuration
  if ! nginx -t; then
    echo "Nginx configuration test failed."
    exit 1
  fi

  # Reload Nginx
  sudo systemctl reload nginx
  echo "Nginx reloaded with new configuration."
}

# Main function
main() {
  install_nginx
  setup_firewall
  domain_name=$(ask_domain_name)
  generate_nginx_conf "$domain_name"

  echo "Setup completed."
}

# Run the main function
main
