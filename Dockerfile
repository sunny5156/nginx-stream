FROM alpine:3.7

MAINTAINER sunny5156 <sunny5156@qq.com> 

#RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.7/main" > /etc/apk/repositories

ARG TZ="Asia/Shanghai"




ENV TZ ${TZ}

ENV WORKER /worker
ENV SRC_DIR ${WORKER}/src

RUN mkdir -p  /data/db ${WORKER}/data

RUN apk upgrade --update \
    && apk add curl bash tzdata openssh \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
    && ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
    && ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa \
    && ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' \
    && ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key -N '' \
    && echo "root:root" | chpasswd \
    && rm -rf /var/cache/apk/*
    
# -----------------------------------------------------------------------------
# Install lrzsz
# ----------------------------------------------------------------------------- 
ENV lrzsz_version 0.12.20
RUN cd ${SRC_DIR} \
    && wget -q -O lrzsz-${lrzsz_version}.tar.gz  http://blog.sunqiang.me/lrzsz-${lrzsz_version}.tar.gz \
    && tar -zxvf lrzsz-${lrzsz_version}.tar.gz  \
    && cd lrzsz-${lrzsz_version} \
    && ./configure \
    && make \
    && make install \
    && ln -s /usr/local/bin/lrz /usr/bin/rz \
	&& ln -s /usr/local/bin/lsz /usr/bin/sz
    
RUN apk add --no-cache git make musl-dev 

ADD shell/.bash_profile /root/
ADD shell/.bashrc /root/
ADD run.sh /

RUN apk add --no-cache gcc gcc-c++ autoconf automake
RUN apk add --no-cache zlib zlib-devel openssl openssl-devel pcre-devel

# -----------------------------------------------------------------------------
# Install nginx
# ----------------------------------------------------------------------------- 
ENV nginx_version 0.12.20
RUN cd ${SRC_DIR} \
    && wget -q -O nginx-${nginx_version}.tar.gz  https://nginx.org/download/nginx-${nginx_version}.tar.gz \
    && tar -zxvf nginx-${nginx_version}.tar.gz  \
    && cd nginx-${nginx_version} \
	&& ./configure --prefix=/usr/local \
	&& --prefix=/etc/nginx \
	&& --sbin-path=/usr/sbin/nginx \
	&& --conf-path=/etc/nginx/nginx.conf \
	&& --error-log-path=/var/log/nginx/error.log \
	&& --http-log-path=/var/log/nginx/access.log \
	&& --pid-path=/var/run/nginx.pid \
	&& --lock-path=/var/run/nginx.lock \
	&& --with-http_stub_status_module \
	&& --with-http_gzip_static_module \
	&& --with-stream \
	&& make \
	&& make install 

RUN mkdir -p /var/cache/nginx

  
RUN echo -e "#!/bin/bash\n/usr/sbin/sshd -D \n nginx -g daemon off" >>/etc/start.sh

#ENTRYPOINT ["/run.sh"]

EXPOSE 80 22 7079 2379 2380

CMD ["/bin/sh","/etc/start.sh"]