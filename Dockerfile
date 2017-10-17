# Inspired by https://github.com/mumoshu/dcind via https://github.com/meAmidos/dcind
FROM docker:dind

ENV DOCKER_COMPOSE_VERSION=1.16.1

# Install Docker and Docker Compose
RUN apk --update --no-cache \
    add git curl device-mapper py-pip iptables && \
    rm -rf /var/cache/apk/* && \
    pip install docker-compose==${DOCKER_COMPOSE_VERSION}

# Install entrykit
RUN curl -L https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_Linux_x86_64.tgz | tar zx && \
    chmod +x entrykit && \
    mv entrykit /bin/entrykit && \
    entrykit --symlink
    
# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source /docker-lib.sh && start_docker
COPY docker-lib.sh /docker-lib.sh

ENTRYPOINT [ \
	"switch", \
		"shell=/bin/sh", "--", \
	"codep", \
		"/bin/docker daemon" \