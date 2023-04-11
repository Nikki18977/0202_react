FROM node:lts-alpine as prod
ENV NODE_ENV production
WORKDIR /app
COPY . .
RUN yarn install &&\
    yarn build

FROM alpine:3.17 as cert
RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/* &&\
    sed -i 's|\[ req \]|\[ req \]\nprompt = no|'  /etc/ssl/openssl.cnf &&\
    sed -i 's|countryName.*= Country Name (2 letter code)|countryName\t= RU |'  /etc/ssl/openssl.cnf &&\
    sed -i 's|stateOrProvinceName.*= State or Province Name (full name)|stateOrProvinceName\t = State|'  /etc/ssl/openssl.cnf &&\
    sed -i 's|localityName.*= Locality Name (eg, city)|localityName\t= MOSCOW|'  /etc/ssl/openssl.cnf &&\
    sed -i 's|0\.organizationName.*= Organization Name (eg, company)|0.organizationName\t= SLURM|'  /etc/ssl/openssl.cnf &&\
    sed -i '/.*_max/d'  /etc/ssl/openssl.cnf &&\
    sed -i '/.*_default/d'  /etc/ssl/openssl.cnf &&\
    sed -i '/.*_min/d'  /etc/ssl/openssl.cnf &&\
    sed -i 's|commonName.*= Common Name (e.g. server FQDN or YOUR name)|commonName\t= local.dev|'  /etc/ssl/openssl.cnf &&\
    openssl req -x509 -nodes -days 30 -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt  

FROM nginx:1.22-alpine
LABEL org.opencontainers.image.source="https://github.com/Nikki18977/0202_react"
ENV SRV_API_IP=backend
ENV SRV_API_PORT=9999
ENV SRV_FRONTEND_NAME=local.dev  

COPY --from=prod /app/build /usr/share/nginx/html
COPY --from=cert /etc/ssl/private/server.key /etc/nginx/keys/server.key
COPY --from=cert /etc/ssl/certs/server.crt  /etc/nginx/keys/server.crt
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
   

 