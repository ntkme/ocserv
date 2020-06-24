# docker-ocserv

``` sh
docker run -d \
  --cap-add NET_ADMIN \
  --hostname $(hostname -f) \
  --publish 443:443/tcp \
  --publish 443:443/udp \
  --volume /etc/letsencrypt:/etc/letsencrypt:ro \
  ntkme/ocserv
```
