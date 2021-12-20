FROM node:16

USER 0

RUN alias ll='ls -l'
RUN apt update && apt install nano

USER 1000