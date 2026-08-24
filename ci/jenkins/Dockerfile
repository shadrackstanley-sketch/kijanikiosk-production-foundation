FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L \
    "https://dl.k8s.io/release/v1.35.1/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN groupadd -g 984 docker-host 2>/dev/null || true \
    && usermod -aG docker-host jenkins

USER jenkins
