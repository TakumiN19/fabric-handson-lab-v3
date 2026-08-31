# Digest pinned from mcr.microsoft.com/devcontainers/python:1-3.12-bookworm.
FROM mcr.microsoft.com/devcontainers/python@sha256:7876580dc67fd460fd962f004cbeb480027e9bbc0657096f1087db11f9eaff39

# This pinned image contains a Yarn apt source with an unavailable signing key.
# The Node Feature does not use it, so remove it before any Feature runs apt update.
RUN rm -f /etc/apt/sources.list.d/yarn.list /etc/apt/sources.list.d/yarn.sources
