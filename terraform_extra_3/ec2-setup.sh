#!/bin/bash
# Update and install dependencies
sudo apt update -y
sudo apt install -y nginx git postgresql postgresql-contrib
sudo snap install go --classic

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Start and enable PostgreSQL
sudo service postgresql start
sudo systemctl enable postgresql


# Define database environment variables (using postgres user)
DB_ENDPOINT="${db_endpoint}"
DB_USER="${db_user}"
DB_PASS="${db_password}"
DB_NAME="${db_name}"
DB_PORT=5432
GIN_MODE=release

# Clone the Golang demo application
cd /home/ubuntu
git clone https://github.com/MoisieievVasya/golang-demo.git
cd golang-demo

# Start PostgreSQL, create database, and apply schema using the postgres user
sudo systemctl start postgresql

# Creating the database
sudo -u postgres psql -f terraform_extra_3/db_schema.sql  
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'password';"

# Build and run the Golang demo application
sudo GOOS=linux GOARCH=amd64 go build -o golang-demo -buildvcs=false
sudo chmod +x golang-demo

# Start the Golang demo application with the environment variables
sudo DB_ENDPOINT=$DB_ENDPOINT DB_PORT=$DB_PORT DB_USER=$DB_USER DB_PASS=$DB_PASS DB_NAME=$DB_NAME ./golang-demo &

# Configure Nginx to proxy requests to the Golang app
sudo bash -c 'cat > /etc/nginx/sites-available/default' << EOF
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Restart Nginx to apply the new configuration
sudo systemctl restart nginx
