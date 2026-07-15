FROM --platform=$BUILDPLATFORM ocaml/opam:debian-ocaml-4.14-nnp@sha256:6dd7a8b14d2d6dbdc5c0d7dcc5bb1bd1136d4b17abe12e9fece2464931bbf9f9 AS builder

ARG GW_VER \
    GW_PR \
    GW_USER=geneweb \
    GW_GROUP=geneweb \
    GW_UID=115 \
    GW_GID=115 \
    OCAML_VER \
    OPAM_VER \
    TARGETOS \
    TARGETARCH

ENV GW_ROOT=/opt/geneweb \
    GWD_PORT=2317 \
    GWC_PORT=2316 \
    HTTP_PORT=80 \
    HTTPS_PORT=443

ENV OPAMYES=yes
ENV OPAMJOBS=2
ENV DUNE_PROFILE=release

USER root
# Install required system dependencies
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install -yq --no-install-recommends \
            brotli \
            libgmp-dev \
            libipc-system-simple-perl \
            libpcre2-dev \
            m4 \
            pkg-config \
            xdot \
            zlib1g-dev \
 && ln -sf /usr/bin/opam-2.3 /usr/bin/opam

# Update local opam repository
USER opam
WORKDIR /home/opam/opam-repository
RUN git fetch origin master \
 && git checkout b69889513d1dfe730791f2fffabe24ca1d944b5f \
 && opam update

# Initialize OPAM
WORKDIR /home/opam
RUN opam init --disable-sandboxing --auto-setup --bare

# Copy opam file for dependency resolution then install dependencies
COPY --chown=opam:opam *.opam ./
RUN opam install . --deps-only --with-test \
 && opam install ancient

# Clone repository and build Geneweb
WORKDIR /home/opam/geneweb
COPY --chown=opam:opam . .
RUN opam exec -- make distrib

###############################################################################
#                                       STAGE 2: Export build via blank image
###############################################################################

FROM scratch AS export
COPY --from=builder /home/opam/geneweb/distribution /

###############################################################################
#                                              STAGE 3: Assemble Docker image
###############################################################################

FROM debian:unstable-slim AS container
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

ENV GENEWEB_HOME=/usr/local/share/geneweb
ENV GENEWEB_DATA_PATH=${GENEWEB_HOME}/share/data
ENV GWSETUP_IP=172.17.0.1

# Install runtime tools and add Geneweb user
# Ignore the apt warning here as apt-get does not allow wildcarding versions
# hadolint ignore=DL3027
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -q \
 && apt install -qy --no-install-recommends openssl adduser netcat-openbsd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && adduser \
     --system \
     --group \
     --uid ${GW_UID} \
     --home ${GENEWEB_HOME} \
       --shell /bin/bash \
       geneweb

RUN pwck -s \
  ; grpck -s

# Do everything in the Geneweb home directory
WORKDIR ${GENEWEB_HOME}

# Create directory structure and configure
RUN mkdir -p bin etc log share/data share/dist \
 && echo "${GWSETUP_IP}" >> etc/gwsetup_only

# Copy application files
COPY --from=builder /home/opam/geneweb/distribution share/dist
COPY docker/geneweb-launch.sh bin/geneweb-launch.sh

# Make script executable, ensure log files exists and update ownership
RUN chmod +x bin/geneweb-launch.sh \
 && touch log/gwsetup.log \
 && touch log/gwd.log \
 && chown -R geneweb:geneweb .

# Switch to geneweb user
USER geneweb

# Configure container

EXPOSE ${GWD_PORT} \
       ${GWC_PORT} \
       ${HTTP_PORT} \
       ${HTTPS_PORT}

VOLUME [ "${GENEWEB_DATA_PATH}", "${GENEWEB_HOME}/etc" ]

HEALTHCHECK --interval=5m \
            --timeout=3s \
            --start-period=30s \
  CMD curl -s --fail http://localhost:${GWD_PORT} -o /dev/null

ENTRYPOINT [ "/bin/bash", "-c", "/opt/geneweb/startup.sh", "$@" ]

# Mandatory Labels
LABEL org.opencontainers.image.vendor=slash5toaster \
      org.opencontainers.image.authors="slash5toaster@gmail.com" \
      org.opencontainers.image.ref.name=geneweb \
      org.opencontainers.image.version=7.1.0-beta

#### End of File, if this is missing the file has been truncated
