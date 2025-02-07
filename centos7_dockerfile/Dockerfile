FROM centos:7

# Remove the existing CentOS Base repo file
RUN cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.old && \
    rm -rf /etc/yum.repos.d/CentOS-Base.repo && \
    echo "# CentOS-Base.repo" > /etc/yum.repos.d/CentOS-Base.repo && \
    echo "[base]" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "name=CentOS-7 - Base" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "baseurl=https://vault.centos.org/7.9.2009/os/\$basearch/" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "[updates]" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "name=CentOS-7 - Updates" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "baseurl=https://vault.centos.org/7.9.2009/updates/\$basearch/" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "[extras]" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "name=CentOS-7 - Extras" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "baseurl=https://vault.centos.org/7.9.2009/extras/\$basearch/" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/CentOS-Base.repo && \
    echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7" >> /etc/yum.repos.d/CentOS-Base.repo

# Clean and update YUM
RUN yum clean all && \
    yum -y update && \
    yum -y install epel-release && \
    yum -y groupinstall "Development Tools" && \
    yum -y install vim wget curl git net-tools iputils bind-utils tar unzip sudo && \
    yum clean all

CMD ["bash"]

