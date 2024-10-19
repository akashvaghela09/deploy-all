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
  ufw enable
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
}

# Main function
main() {
  install_nginx
  setup_firewall
  ask_domain_name

  echo "Setup completed."
}

# Run the main function
main
