FROM centos:7.4.1708

RUN yum -y update
RUN yum install -y wget \
                   httpd \
                   openssh-server \
                   openssh-clients \
                   sysstat

# install epel repo
RUN wget 'https://centos.anexia.at/epel/epel-release-latest-7.noarch.rpm' \
    && rpm -ivh epel-release-latest-7.noarch.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum

#install supervisord

RUN yum install -y --enablerepo=epel \
                   supervisor \
                   python3-pip \
    && yum clean all \
    && rm -rf /var/cache/yum             

# install the python docker client
RUN pip3 install docker

#configure supervisord

RUN mkdir -p /var/log/supervisor
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN echo "files = /etc/supervisor/conf.d/*.conf" >> /etc/supervisord.conf

#create ssh keys

RUN /usr/sbin/sshd-keygen 2>/dev/null

COPY ssh-keys/rubis_rsa_key.pub root/.ssh/authorized_keys

ENV WEB_NAME web
#ENV MEMBER_1 rubis

COPY ./cluster /root/cluster
RUN chmod +x root/.ssh/authorized_keys

#configure apache2.4 (enable monitoring and set a OVERSIZED thread pool)
RUN rm -f /etc/httpd/conf.modules.d/00-mpm.conf
COPY ./conf/11-mod_status.conf /etc/httpd/conf.modules.d/
COPY ./conf/00-mpm.conf /etc/httpd/conf.modules.d/

RUN rm -f /var/www/html/index.html 

# forward access and error logs to docker log collector
#RUN ln -sf /dev/stdout /var/log/httpd/access_log \
#	&& ln -sf /dev/stderr /var/log/httpd/error_log

EXPOSE 80

CMD ["-c","/etc/supervisord.conf"]
ENTRYPOINT ["/usr/bin/supervisord"]
