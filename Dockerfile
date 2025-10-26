FROM mlikiowa/napcat-docker:base

RUN useradd --no-log-init -d /app napcat

WORKDIR /app


# 下载NapCat和安装Linux QQ
RUN version=$(curl -s "https://api.github.com/repos/NapNeko/NapCatQQ/releases/latest" | jq -r '.tag_name') && \
    echo "下载NapCat版本: $version" && \
    curl -s -L "https://github.com/NapNeko/NapCatQQ/releases/download/$version/NapCat.Shell.zip" -o NapCat.Shell.zip && \
    mkdir -p /app/napcat/config && \
    unzip -q NapCat.Shell.zip -d ./NapCat.Shell && \
    cp -rf NapCat.Shell/* napcat/ && \
    cp -rf NapCat.Shell/config/* napcat/config/ || true && \
    rm -rf ./NapCat.Shell NapCat.Shell.zip && \
    arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
    curl -o linuxqq.deb https://dldir1.qq.com/qqfile/qq/QQNT/ab90fdfa/linuxqq_3.2.20-40768_${arch}.deb && \
    dpkg -i --force-depends linuxqq.deb && rm linuxqq.deb && \
    echo "(async () => {await import('file:///app/napcat/napcat.mjs');})();" > /opt/QQ/resources/app/loadNapCat.js && \
    sed -i 's|"main": "[^"]*"|"main": "./loadNapCat.js"|' /opt/QQ/resources/app/package.json

VOLUME /app/napcat/config
VOLUME /app/.config/QQ

RUN apt-get update && apt-get install -y supervisor && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/log/supervisor

ENV DISPLAY=:1 \
    FFMPEG_PATH=/usr/bin/ffmpeg

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-start.sh /usr/local/bin/docker-start.sh
RUN chmod +x /usr/local/bin/docker-start.sh

ENTRYPOINT ["/usr/local/bin/docker-start.sh"]
