FROM couchbase/server:enterprise-6.6.0

LABEL MAINTAINER="Etops AG"

ENV ADMIN_LOGIN $ADMIN_LOGIN
ENV ADMIN_PASSWORD $ADMIN_PASSWORD

# Curl is needed as a diagnostic tool during build.
RUN apt-get update && \
    apt-get install -yq curl && \
    apt-get autoremove && \
    apt-get clean


COPY init.sh /
RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]

# 8091: Couchbase Web console, REST/HTTP interface
# 8092: Views, queries, XDCR
# 8093: Query services (4.0+)
# 8094: FTS
# 8096: Eventing
# 9110: Full-text Serarch (4.5 DP; will be 8094 in 4.5+)
# 11207: Smart client library data node access (SSL)
# 11210: Smart client library/moxi data node access
# 11211: Legacy non-smart client library data node access
# 18091: Couchbase Web console, REST/HTTP interface (SSL)
# 18092: Views, query, XDCR (SSL)
EXPOSE 8091 8092 8093 8094 8096 9110 11207 11210 11211 18091 18092
