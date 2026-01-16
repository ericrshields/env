#!/bin/bash
# Archive of obsolete web server management aliases and functions
# These are preserved for reference but no longer sourced in active shell
# Most are CentOS/RHEL specific or for Apache/MySQL server management

# Apache HTTPD configuration deployment
# CentOS/RHEL specific, copies config files and restarts Apache
alias apache_config="sudo cp ~/env/not_symlinked/httpd/sites/* /etc/httpd/conf.d/ && sudo cp ~/env/not_symlinked/httpd/httpd.conf /etc/httpd/conf/httpd.conf && sudo systemctl restart httpd"

# MySQL instance management via init.d (pre-systemd)
# Toggles multiple MySQL instances
# @author ezarko/eshields
sqltoggle() {
    for i in /etc/init.d/mysqld-*; do sudo $i $1; done
}

# CentOS/RHEL init.d functions
# Source CentOS-specific init functions (colored output, daemon management, etc.)
# [[ -f /etc/init.d/functions ]] && . /etc/init.d/functions

# Modern replacements:
# - Apache: Use Docker/nginx/systemd: systemctl restart httpd
# - MySQL: Use systemd: systemctl start mysql
# - Init functions: systemd provides equivalent functionality
