# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM python:3.12-slim

EXPOSE 6385

RUN apt-get update && apt-get install -y --no-install-recommends \
	iproute2 \
	isolinux \
	syslinux-utils \
	xorriso \
	genisoimage \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/lib/syslinux && \
	ln -sf /usr/lib/ISOLINUX/isolinux.bin /usr/lib/syslinux/isolinux.bin || true

RUN mkdir -p /etc/ironic /var/log/ironic /shared/html

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
	&& rm /tmp/requirements.txt

COPY entrypoint.sh /usr/local/bin/ironic-entrypoint
RUN chmod +x /usr/local/bin/ironic-entrypoint

ENTRYPOINT ["/usr/local/bin/ironic-entrypoint"]
CMD []