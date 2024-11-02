FROM steamcmd/steamcmd:debian-12

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

COPY version /server/version
COPY server /server/server

ENTRYPOINT ["/server/server"]
