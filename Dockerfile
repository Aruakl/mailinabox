# Mail-in-a-Box Dockerfile
# Based on Ubuntu 22.04 LTS as required by the installation scripts
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_TYPE=en_US.UTF-8
ENV NCURSES_NO_UTF8_ACS=1

# Set timezone (can be overridden via environment variable)
ENV TZ=UTC

# Install basic system packages first
RUN apt-get update && apt-get install -y \
    locales \
    tzdata \
    && locale-gen en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# Install essential packages required by Mail-in-a-Box
RUN apt-get update && apt-get install -y \
    # Basic utilities
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    netcat-openbsd \
    wget \
    curl \
    git \
    sudo \
    coreutils \
    bc \
    file \
    pollinate \
    openssh-client \
    unzip \
    # System services
    unattended-upgrades \
    cron \
    ntp \
    fail2ban \
    rsyslog \
    # Add software-properties-common for add-apt-repository
    software-properties-common \
    # DNS and networking
    bind9 \
    # Firewall (UFW) - though may be disabled in container
    ufw \
    # Mail server components
    postfix \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    dovecot-lmtpd \
    dovecot-managesieved \
    # Web server
    nginx \
    # PHP (version 8.0 as specified in functions.sh)
    php8.0 \
    php8.0-fpm \
    php8.0-cli \
    php8.0-common \
    php8.0-mysql \
    php8.0-zip \
    php8.0-gd \
    php8.0-mbstring \
    php8.0-curl \
    php8.0-xml \
    php8.0-bcmath \
    php8.0-imap \
    php8.0-ldap \
    php8.0-intl \
    # Database
    sqlite3 \
    # Spam filtering
    spamassassin \
    # DNS server
    nsd \
    # SSL/TLS
    certbot \
    # Backup tools
    duplicity \
    # Monitoring
    munin \
    munin-node \
    # Z-Push dependencies
    php8.0-soap \
    # Additional tools
    dialog \
    && rm -rf /var/lib/apt/lists/*

# Add PPAs required by Mail-in-a-Box
RUN add-apt-repository -y universe \
    && add-apt-repository -y ppa:duplicity-team/duplicity-release-git \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update --allow-releaseinfo-change

# Create mailinabox user and directories
RUN useradd -m -s /bin/bash mailinabox \
    && mkdir -p /home/mailinabox/mailinabox \
    && mkdir -p /home/user-data

# Copy the Mail-in-a-Box source code
COPY . /home/mailinabox/mailinabox/

# Set working directory
WORKDIR /home/mailinabox/mailinabox

# Set proper permissions
RUN chown -R mailinabox:mailinabox /home/mailinabox \
    && chown -R mailinabox:mailinabox /home/user-data \
    && chmod +x setup/*.sh \
    && chmod +x tools/*

# Create necessary directories and files
RUN mkdir -p /var/log/mailinabox \
    && touch /var/log/mailinabox/setup.log

# Set environment variables for non-interactive setup
ENV NONINTERACTIVE=1
ENV SKIP_NETWORK_CHECKS=1
ENV DISABLE_FIREWALL=1

# Expose necessary ports
# SMTP: 25, 587, 465
# IMAP: 143, 993
# POP3: 110, 995
# HTTP: 80
# HTTPS: 443
# DNS: 53
# Management: 10222
EXPOSE 25 53/tcp 53/udp 80 110 143 443 465 587 993 995 10222

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Start essential services\n\
service rsyslog start\n\
service cron start\n\
\n\
# Initialize random number generator\n\
echo "Initializing system random number generator..."\n\
dd if=/dev/urandom of=/dev/random bs=1 count=32 2>/dev/null || true\n\
\n\
# Set hostname if provided\n\
if [ -n "${PRIMARY_HOSTNAME:-}" ]; then\n\
    echo "$PRIMARY_HOSTNAME" > /etc/hostname\n\
    hostname "$PRIMARY_HOSTNAME"\n\
fi\n\
\n\
# Run Mail-in-a-Box setup if not already configured\n\
if [ ! -f /etc/mailinabox.conf ]; then\n\
    echo "Running Mail-in-a-Box initial setup..."\n\
    cd /home/mailinabox/mailinabox\n\
    sudo -E ./setup/start.sh\n\
else\n\
    echo "Mail-in-a-Box already configured, starting services..."\n\
    # Start services\n\
    service postfix start || true\n\
    service dovecot start || true\n\
    service nginx start || true\n\
    service bind9 start || true\n\
    service nsd start || true\n\
    service fail2ban start || true\n\
    service spamassassin start || true\n\
fi\n\
\n\
# Keep container running\n\
echo "Mail-in-a-Box container started successfully"\n\
tail -f /var/log/syslog\n\
' > /start.sh && chmod +x /start.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Set the startup command
CMD ["/start.sh"]
