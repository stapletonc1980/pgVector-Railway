FROM postgres:17

RUN apt-get update && \
    apt-get install -y build-essential git postgresql-server-dev-17 && \
    git clone https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && \
    make install && \
    cd .. && \
    rm -rf pgvector && \
    apt-get remove --purge -y build-essential git postgresql-server-dev-17 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY init.sql /docker-entrypoint-initdb.d/init.sql

# Password-reset entrypoint: runs on every container start so the postgres
# user password always matches POSTGRES_PASSWORD, even with an existing volume.
COPY reset-password.sh /usr/local/bin/reset-password.sh
RUN chmod +x /usr/local/bin/reset-password.sh

ENTRYPOINT ["reset-password.sh"]
CMD ["postgres"]
