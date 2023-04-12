FROM node:lts-alpine as first-builder

ENV NODE_ENV production

WORKDIR /app
COPY . .
RUN yarn install &&\
    yarn build


FROM alpine:3.17 as second-builder

ENV CONTRY_NAME=RU
ENV PROVINCE_NAME=Moscow
ENV LOCALITY_NAME=Moscow
ENV ORG_NAME=Slurm
ENV COMMON_NAME=local.dev
ENV EXP_DAY=30
ENV RSA_SIZE=2048
ENV ALT_IP=127.0.0.1

RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/* &&\
    openssl req -x509 -nodes -days ${EXP_DAY} -newkey rsa:${RSA_SIZE} \
    -keyout /etc/ssl/private/server.key \
    -out /etc/ssl/certs/server.crt \
    -subj "/C=${CONTRY_NAME}/ST=${PROVINCE_NAME}/L=${LOCALITY_NAME}/O=${ORG_NAME}/CN=${COMMON_NAME}" \
    -addext "subjectAltName = IP:${ALT_IP}"


FROM nginx:1.22-alpine as final-builder
LABEL org.opencontainers.image.source="https://github.com/Nikki18977/0202_react"

ENV SRV_API_IP=backend
ENV SRV_API_PORT=9999
ENV SRV_FRONTEND_NAME=local.dev 

COPY --from=first-builder /app/build /usr/share/nginx/html
COPY --from=second-builder /etc/ssl/private/server.key /etc/nginx/keys/server.key
COPY --from=second-builder /etc/ssl/certs/server.crt  /etc/nginx/keys/server.crt
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
   

