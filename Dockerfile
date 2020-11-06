FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openssh-server
RUN apt-get install -y gcc g++
RUN apt-get install -y build-essential
ENV STRESS=stress_result.txt \
SHELL=/bin/bash
RUN mkdir /var/run/sshd
RUN mkdir /stress
RUN pwd
RUN echo 'root:Intel123!' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

WORKDIR /stress
RUN wget http://kernel.ubuntu.com/~cking/tarballs/stress-ng/stress-ng-0.09.34.tar.xz
RUN tar xvf stress-ng-0.09.34.tar.xz
WORKDIR stress-ng-0.09.34
RUN make

#cpu stress test
RUN uptime > $STRESS
RUN stress-ng --cpu 4 --timeout 60s --metrics-brief >> $STRESS
RUN uptime >> $STRESS
RUN stress-ng --disk 2 --timeout 60s --metrics-brief >> $STRESS

#memory stress test
RUN stress-ng --vm 2 --vm-bytes 1G --timeout 60s >> $STRESS

#stress all
RUN stress-ng --cpu 4 --io 2 --vm 1 --vm-bytes 1G --timeout 60s --metrics-brief >> $STRESS

#run all the stressors in the io class one by one for 1 minutes each
RUN stress-ng --sequential 8 --class io -t 1m --times >> $STRESS
RUN ls
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
