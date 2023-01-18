# docker-opengrok-archlinux

Browse Archlinux sources in one go

The scripts assumes to be working in the current directory (that is, the directory that contains this README.md).

Also, Archlinux installation is assumed.

## Steps to use

- Prepare packages
  - Use `genDepTree.sh` to collect Arch packages
    - Implemented a silly dependency resolving using expac, do install this first
      - Will not resolve the dependency that utilize `provides`
    - Automatically excludes `base` packages and associated dependencies
  - Use `getPkgsAUR.sh` to collect AUR packages of interest
    - No dependency resolution implemented
  - Use `extractSources.sh` to extract all sources to `extracted/`
- Start OpenGrok: `docker run -d -p 127.0.0.1:8080:8080 --cpus=8 --memory=8g -e NOMIRROR=1 -v $(pwd)/extracted/:/opengrok/src opengrok/docker:1.7`
  - Requires ~2G mem for labwc and related dependencies (61 items)

## Future work

- [ ] Add dockerized building to allow for any Linux with Docker installed
- [ ] Hosting, or change to static ones and host with GitHub Pages
  - But OpenGrok seems way better than other alternatives in term of usability