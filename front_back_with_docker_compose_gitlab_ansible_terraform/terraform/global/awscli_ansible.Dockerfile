# The docker image for build and deploy jobs
FROM alpine:3.19
RUN apk update
RUN apk add ansible aws-cli docker git openssh-client
USER root
CMD ["/bin/sh"]