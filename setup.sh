#!/bin/bash
#
# Setup or upgrade a server to run the components necessary for a node in the logging cluster
#   - redis
#   - logstash
#   - elasticsearch
#

##############################################################################################
# Properties
##############################################################################################
export SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
export APP_HOME="/app"

export JDK_URL="https://edelivery.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.rpm"
export JDK_NAME="jdk1.7.0_45"

export ELASTICSEARCH_URL="https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.9.noarch.rpm"
export ELASTICSEARCH_HOME="${APP_HOME}/elasticsearch"

export REDIS_URL="http://download.redis.io/releases/redis-2.8.3.tar.gz"
export REDIS_NAME="redis-2.8.3"
export REDIS_HOME="${APP_HOME}/redis"

export LOGSTASH_URL="https://download.elasticsearch.org/logstash/logstash/logstash-1.3.2-flatjar.jar"
export LOGSTASH_NAME="logstash-1.3.2"
export LOGSTASH_HOME="${APP_HOME}/logstash"

##############################################################################################
# Java
##############################################################################################

curl -v --location --insecure --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" ${JDK_URL} > /tmp/${JDK_NAME}.rpm
rpm -Uvh /tmp/${JDK_NAME}.rpm

# Make sure to set defaults
# http://d.stavrovski.net/blog/post/how-to-install-and-setup-oracle-java-jdk-in-centos-6
alternatives --install /usr/bin/java java /usr/java/${JDK_NAME}/jre/bin/java 20000
alternatives --install /usr/bin/jar jar /usr/java/${JDK_NAME}/bin/jar 20000
alternatives --install /usr/bin/javac javac /usr/java/${JDK_NAME}/bin/javac 20000
alternatives --install /usr/bin/javaws javaws /usr/java/${JDK_NAME}/jre/bin/javaws 20000
alternatives --set java /usr/java/${JDK_NAME}/jre/bin/java
alternatives --set javaws /usr/java/${JDK_NAME}/jre/bin/javaws
alternatives --set javac /usr/java/${JDK_NAME}/bin/javac
alternatives --set jar /usr/java/${JDK_NAME}/bin/jar

rm /tmp/${JDK_NAME}.rpm

which java
java -version

##############################################################################################
# Elasticsearch
##############################################################################################

curl -v --location --insecure ${ELASTICSEARCH_URL} > /tmp/elasticsearch.install.rpm
rpm -Uvh /tmp/elasticsearch.install.rpm
rm /tmp/elasticsearch.install.rpm

mkdir -p ${ELASTICSEARCH_HOME}/data
chown -R elasticsearch:elasticsearch ${ELASTICSEARCH_HOME}

mkdir -p /tmp/elasticsearch
mkdir -p /var/log/elasticsearch
chown -R elasticsearch:elasticsearch /tmp/elasticsearch /var/log/elasticsearch

cp ${SCRIPT_DIR}/elasticsearch/elasticsearch /etc/sysconfig/elasticsearch
cp ${SCRIPT_DIR}/elasticsearch/*.yml /etc/elasticsearch

##############################################################################################
# Redis
##############################################################################################

yum -y install gcc

mkdir -p ${REDIS_HOME}
curl -v --location --insecure ${REDIS_URL} > ${REDIS_HOME}/${REDIS_NAME}.tar.gz
tar -xzf ${REDIS_HOME}/${REDIS_NAME}.tar.gz -C ${REDIS_HOME}
rm ${REDIS_HOME}/${REDIS_NAME}.tar.gz

cd ${REDIS_HOME}/${REDIS_NAME}
make install
rm -rf ${REDIS_HOME}/${REDIS_NAME}

useradd -r redis

mkdir -p ${REDIS_HOME}/work
chown -R redis:redis ${REDIS_HOME}

mkdir -p /var/run/redis
mkdir -p /var/log/redis
chown -R redis /var/run/redis /var/log/redis

cp  ${SCRIPT_DIR}/redis/redis.conf /etc
cp  ${SCRIPT_DIR}/redis/logrotate /etc/logrotate.d/redis
cp  ${SCRIPT_DIR}/redis/redis /etc/init.d/redis
chmod 755 /etc/init.d/redis
chkconfig --add redis
chkconfig --level 345 redis on

##############################################################################################
# Logstash
##############################################################################################

useradd -r logstash

mkdir -p ${LOGSTASH_HOME}
curl -v --location --insecure ${LOGSTASH_URL} > ${LOGSTASH_HOME}/${LOGSTASH_NAME}.jar
cd ${LOGSTASH_HOME}
ln -sfn ${LOGSTASH_NAME}.jar current.jar

mkdir -p /var/run/logstash
mkdir -p /var/log/logstash
chown -R logstash /var/run/logstash /var/log/logstash

cp -r ${SCRIPT_DIR}/logstash/logstash /etc/init.d/logstash
chmod 755 /etc/init.d/logstash
mkdir -p ${LOGSTASH_HOME}/conf
cp  ${SCRIPT_DIR}/logstash/conf/* ${LOGSTASH_HOME}/conf
mkdir -p ${LOGSTASH_HOME}/tmp
mkdir -p ${LOGSTASH_HOME}/patterns
cp ${SCRIPT_DIR}/logstash/patterns/* ${LOGSTASH_HOME}/patterns
chown -R logstash:logstash ${LOGSTASH_HOME}

##############################################################################################
# Start Services
##############################################################################################
service elasticsearch stop
service elasticsearch start

service redis stop
service redis start

service logstash stop
service logstash start