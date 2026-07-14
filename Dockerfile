ARG DEBIAN_DIST=bookworm
FROM debian:bookworm

ARG DEBIAN_DIST
ARG ruff_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG RUFF_RELEASE

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/ruff
RUN mkdir -p /output/DEBIAN

COPY ${RUFF_RELEASE}/* /output/usr/bin/
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/ruff/
COPY output/changelog.Debian /output/usr/share/doc/ruff/
COPY output/README.md /output/usr/share/doc/ruff/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/ruff/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/ruff/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/ruff_VERSION/$ruff_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN dpkg-deb --build /output /ruff_${FULL_VERSION}.deb
