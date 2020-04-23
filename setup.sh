echo "Creating database validicity"
sudo psql -c "create database validicity; create user validicity;alter user validicity with password 'validicity';grant all on database validicity to validicity;" -U postgres
