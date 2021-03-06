FROM debian:buster
MAINTAINER ActiDoo <info@actidoo.com>

ENV LDAP_URI=ldap://ldap.host.net/ \
    LDAP_BASE=dc=example,dc=com \
    LDAP_TLS_STARTTLS=false \
    LDAP_HOMEDIR=/home/%u \
    LDAP_ATTR_SSHPUBLICKEY=sshPublicKey \
    SFTP_CHROOT=/sftp_data
#   LDAP_BASE_USER=cn=users,dc=example,dc=com
#   LDAP_BASE_GROUP=cn=groups,dc=example,dc=com
#   LDAP_BIND_USER=cn=sssd,dc=example,dc=net
#   LDAP_BIND_PWD=xxxxxxxx
#   LDAP_TLS_CACERT=/etc/ssl/ca.crt
#   LDAP_TLS_CERT=/etc/ssl/cert.crt
#   LDAP_TLS_KEY=/etc/ssl/cert.key

# Add mysecureshell repository

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" \
     -o Dpkg::Options::="--force-confold" install \
      acl \
      whois \
      procps \
      openssh-server \
      libnss-sss \
      libpam-sss \
      openssh-server \
      openssh-sftp-server \
      sssd-ldap \
      git-core \
      libacl1-dev\
      build-essential\
      supervisor && \
# Clean dependencies
    apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* && \
# Remove default debian keys
    rm -f /etc/ssh/ssh_host_*key* && \
    mkdir /var/run/sshd && chmod 0755 /var/run/sshd && \
# Prepare data dir
    mkdir -p /sftp_data && \
# Configure sshd
    sed -i 's|^AuthorizedKeysFile|#AuthorizedKeysFile|' /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysFile /etc/ssh/authorized_keys' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys' >> /etc/ssh/sshd_config && \
    sed -i 's|/usr/lib/openssh/sftp-server$|/usr/bin/mysecureshell -c sftp-server|' /etc/ssh/sshd_config && \
#    echo 'ForceCommand internal-sftp' >> /etc/ssh/sshd_config && \
#    echo 'ChrootDirectory SFTP_CHROOT' >> /etc/ssh/sshd_config && \
    cd /root && \
    git clone https://github.com/mysecureshell/mysecureshell && \
    cd mysecureshell && \
    ./configure --with-logcolor=yes && \
    make all && \
    make install && \
    chmod 4755 /usr/bin/mysecureshell

# copy local files
COPY root/ /

RUN chown root:root /sftp_data && \
    chmod 755 /sftp_data && \
    chmod 600 /etc/sssd/sssd.conf && \
    chmod +x /start.sh

EXPOSE 22
VOLUME ["/sftp_data", "/etc/ssh_keys"]
WORKDIR /

CMD ["/start.sh"]