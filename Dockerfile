FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    strongswan \
    xl2tpd \
    ppp \
    iptables \
    net-tools \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /etc/ipsec.d /var/run/xl2tpd

# Copy configuration files
COPY config/ipsec.conf /etc/ipsec.conf
COPY config/ipsec.secrets /etc/ipsec.secrets
COPY config/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
COPY config/options.xl2tpd /etc/ppp/options.xl2tpd
COPY config/chap-secrets /etc/ppp/chap-secrets

# Copy startup script
COPY scripts/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose required ports
# UDP 500 (IKE), UDP 4500 (NAT-T), UDP 1701 (L2TP)
EXPOSE 500/udp 4500/udp 1701/udp

# Use the startup script as entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]
