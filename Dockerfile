FROM docker.io/library/alpine:latest

ARG OCSERV_BRANCH

RUN apk add --no-cache freeradius-client gnutls iptables ip6tables krb5-libs libev libmaxminddb libnl3 libseccomp lz4-libs linux-pam oath-toolkit-liboath readline shadow \
 && apk add --no-cache --virtual .build-deps alpine-sdk autoconf automake freeradius-client-dev gnutls-dev gperf krb5-dev libev-dev libseccomp-dev linux-pam-dev lz4-dev libmaxminddb-dev libnl3-dev oath-toolkit-dev protobuf-c-compiler readline-dev \
 && git clone --branch "${OCSERV_BRANCH:-$(curl -fsSL "https://gitlab.com/api/v4/projects/openconnect%2Focserv/repository/tags" | grep -o '"name":"[^"]\+"' | head -n 1 | cut -d '"' -f 4)}" --depth 1 -- https://gitlab.com/openconnect/ocserv.git \
 && cd ocserv \
 && autoreconf -fiv \
 && ./configure \
 && make \
 && make install \
 && mkdir -p /etc/ocserv \
 && sed -e '/^\[vhost:/,$d' \
        -e '/^auth\|^max-same-clients\|^default-domain\|^dns\|^route\|^no-route/s/^/#/' \
        -e '/^#auth = "certificate"/s/^#//' \
        -e '/^#acct = /a acct = "pam"' \
        -e '/^server-cert = /s/=.*$/= \/etc\/ocserv\/certs\/server-cert.pem/' \
        -e '/^server-key = /s/=.*$/= \/etc\/ocserv\/certs\/server-key.pem/' \
        -e '/^ca-cert = /s/=.*$/= \/etc\/ocserv\/certs\/ca-cert.pem/' \
        -e '/^try-mtu-discovery = /s/=.*$/= true/' \
        -e '/^cert-user-oid = /s/=.*$/= 2.5.4.3/' \
        -e '/^#compression = true/s/^#//' \
        -e '/^tls-priorities = /s/=.*$/= "SECURE256:+SECURE128:-VERS-TLS1.0:-VERS-TLS1.1:-VERS-DTLS1.0:-AES-128-CBC:-AES-128-CCM:-AES-256-CBC:-AES-256-CCM:-RSA:-SHA1"/' \
        -e '/^#dns = /{' \
        -e 'a dns = 1.1.1.1' \
        -e 'a dns = 1.0.0.1' \
        -e 'a dns = 2606:4700:4700::1111' \
        -e 'a dns = 2606:4700:4700::1001' \
        -e '}' \
        -e '/^#route = default/s/^#//' \
        -- doc/sample.config \
  | tee /etc/ocserv/ocserv.conf \
 && cd .. \
 && rm -rf ocserv \
 && git clone --depth 1 -- https://github.com/ntkme/certrdn.git \
 && cd certrdn \
 && autoreconf -fiv \
 && ./configure \
 && make \
 && make install \
 && cd .. \
 && rm -rf certrdn \
 && apk del --purge .build-deps \
 && which occtl ocpasswd ocserv \
  | xargs -n 1 ldd \
 && ocserv --version \

EXPOSE 443/tcp
EXPOSE 443/udp

ENTRYPOINT ["/bin/sh", "-c", "test -f /etc/ocserv/certs/server-cert.pem -a -f /etc/ocserv/certs/server-key.pem -a -f /etc/ocserv/certs/ca-cert.pem || { test -d /etc/letsencrypt && { test -f /etc/letsencrypt/live/$(hostname)/fullchain.pem -a -f /etc/letsencrypt/live/$(hostname)/privkey.pem -a -f /etc/letsencrypt/live/$(hostname)/chain.pem && mkdir -p /etc/ocserv/certs && ln -sf /etc/letsencrypt/live/$(hostname)/fullchain.pem /etc/ocserv/certs/server-cert.pem && ln -sf /etc/letsencrypt/live/$(hostname)/privkey.pem /etc/ocserv/certs/server-key.pem && ln -sf /etc/letsencrypt/live/$(hostname)/chain.pem /etc/ocserv/certs/ca-cert.pem || timeout 10 sleep infinity; }; } || exit 1 && find /etc/ocserv/certs -name '*.pem' -exec sh -c 'useradd -d /dev/null -g nogroup -r -s /sbin/nologin \"$(certrdn 2.5.4.3 \"$1\")\"' -- {} \\; || true && test -c /dev/net/tun || { mkdir -p /dev/net && mknod -m 666 /dev/net/tun c 10 200; } && iptables --table nat --check POSTROUTING --jump MASQUERADE || iptables --table nat --append POSTROUTING --jump MASQUERADE && exec ocserv -f \"$@\"", "--"]
CMD ["-c", "/etc/ocserv/ocserv.conf"]
