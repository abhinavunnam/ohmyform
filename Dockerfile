## Build API
FROM node:12-alpine as api

WORKDIR /usr/src/app

COPY ui/ .

RUN yarn install --frozen-lockfile
RUN yarn export

## Build APP
FROM node:12-alpine as app
LABEL maintainer="OhMyForm <admin@ohmyform.com>"

WORKDIR /usr/src/app

RUN apk update && apk add curl bash && rm -rf /var/cache/apk/*

# install node-prune (https://github.com/tj/node-prune)
RUN curl -sfL https://install.goreleaser.com/github.com/tj/node-prune.sh | bash -s -- -b /usr/local/bin


COPY api/ .
COPY --from=api /usr/src/app/out /usr/src/app/public

RUN yarn install --frozen-lockfile
RUN yarn build

# remove development dependencies
RUN npm prune --production

# run node prune
RUN /usr/local/bin/node-prune

## Glue
RUN touch /usr/src/app/src/schema.gql && chown 9999:9999 /usr/src/app/src/schema.gql

## Production Image.
FROM node:12-alpine

WORKDIR /usr/src/app
COPY --from=app /usr/src/app /usr/src/app
RUN addgroup --gid 9999 ohmyform && adduser -D --uid 9999 -G ohmyform ohmyform
#ENV PORT=3000 \
#    SECRET_KEY=ChangeMe
#    CREATE_ADMIN=FALSE \
#    ADMIN_EMAIL=admin@ohmyform.com \
#    ADMIN_USERNAME=root \
#    ADMIN_PASSWORD=root
ENV PORT=3000 \
    SECRET_KEY=DonotTellItAnyone \
    NODE_ENV=secure \
    CREATE_ADMIN=TRUE \
    MAILER_FROM=defaultEmailForMailing@gmail.com \
    ADMIN_EMAIL=gaurav111986@gmail.com \
    ADMIN_USERNAME=defaultUser \
    ADMIN_PASSWORD=default \
    LOGIN_NOTE="WELCOME TO FORM FILLING EXPERIENCE" \
    DEFAULT_ROLE=admin \
    HIDE_CONTRIB=TRUE

EXPOSE 3000
USER ohmyform
CMD [ "yarn", "start:prod" ]
