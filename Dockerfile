FROM alpine:3.11.2
RUN apk add --no-cache python3 python3-dev gcc libc-dev linux-headers && \
    pip3 install Flask psutil && \
    apk del python3-dev gcc libc-dev linux-headers && \
    rm -rf /var/cache/apk/* /root/.cache
EXPOSE 80
COPY app.py /usr/src/app/
CMD [ "python3", "/usr/src/app/app.py" ]

