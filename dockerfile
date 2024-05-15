# Use Red Hat Universal Base Image (UBI) as the base image
FROM registry.access.redhat.com/ubi8/ubi

# Install PHP and other necessary dependencies
RUN yum install -y php php-mysqlnd php-xml php-gd php-opcache php-intl php-mbstring

# Expose port 80
EXPOSE 80

# Start Apache web server
CMD ["httpd", "-D", "FOREGROUND"]
