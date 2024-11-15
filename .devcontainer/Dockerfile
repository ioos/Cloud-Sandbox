FROM infrastructurebuilder/ansible-container:latest
ENV HOME "/root"
ENV PATH "${HOME}/.local/bin:${PATH}"
RUN <<SCRIPT1
dnf -y update
dnf install -y libffi-devel ruby-devel gcc-c++ make
SCRIPT1
