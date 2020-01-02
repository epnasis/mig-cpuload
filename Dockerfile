FROM alpine:3.11.2
RUN apk add --no-cache python3
RUN apk add --no-cache --virtual build-packages python3-dev gcc libc-dev linux-headers \
    && pip3 --disable-pip-version-check install Flask psutil \
    && apk del build-packages \
    && rm -rf /root/.cache
EXPOSE 80
WORKDIR /usr/src/app
COPY app.py .
CMD [ "python3", "app.py" ]

