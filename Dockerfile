FROM flyway/flyway:10

COPY ./migrations/flyway /flyway/sql
COPY ./flyway/flyway.conf /flyway/conf/flyway.conf

CMD ["migrate"]