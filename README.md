# container-ocserv

``` sh
docker run -d \
  --cap-add MKNOD \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --hostname $(hostname -f) \
  --publish 443:443/tcp \
  --publish 443:443/udp \
  --volume /etc/letsencrypt:/etc/letsencrypt:ro \
  ghcr.io/ntkme/ocserv
```
