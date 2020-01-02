FROM alpine:3.11.2
RUN apk add --no-cache python3
RUN apk add --no-cache --virtual build-packages python3-dev gcc libc-dev linux-headers \
    && pip3 --disable-pip-version-check install Flask psutil \
    && apk del build-packages \
    && rm -rf /root/.cache
EXPOSE 80
COPY app.py /usr/src/app/
CMD [ "python3", "/usr/src/app/app.py" ]

