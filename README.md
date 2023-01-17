# docker-opengrok-archlinux

Browse Archlinux sources in one go

- Prepare packages
- Start OpenGrok: `docker run -d -p 127.0.0.1:8080:8080 --cpus=2 --memory=8g -v  $(pwd)/extracted/:/opengrok/src opengrok/docker:1.7`