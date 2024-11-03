# Pins to a specific commit of the steamcmd's debian-12 image
# because it retags every night, causing a lot of churn
FROM steamcmd/steamcmd@sha256:ac10683f263f40499ea209b45278f808cf6917fadb4cc36d60fe046c7039c393

# Steam clients
EXPOSE 16261/udp
# Raknet clients
EXPOSE 16262/udp
# RCON
EXPOSE 27015/tcp

RUN adduser spiffo

RUN mv /root/.local /home/spiffo/.local
RUN chown --recursive spiffo:spiffo /home/spiffo/.local

RUN mkdir /server /game-data
RUN chown spiffo:spiffo /server /game-data
VOLUME /game-data

USER spiffo
ENV HOME=/home/spiffo

RUN steamcmd \
    +force_install_dir /server \
    +login anonymous \
    +app_update 380870 validate \
    +quit

WORKDIR /game-data

ARG RCON_VERSION=0.10.3
ARG RCON_FILE_BASE=rcon-${RCON_VERSION}-amd64_linux

ADD --chown=spiffo:spiffo https://github.com/gorcon/rcon-cli/releases/download/v${RCON_VERSION}/${RCON_FILE_BASE}.tar.gz /tmp/rcon.tar.gz
RUN cd /server && \
    tar xvf /tmp/rcon.tar.gz -C /tmp && \
    mv /tmp/${RCON_FILE_BASE}/rcon /server/_rcon && \
    rm -rf /tmp/${RCON_FILE_BASE}

COPY rcon /server/rcon
COPY version /server/version
COPY health /server/health
COPY start /server/start

ENTRYPOINT ["/server/start"]
