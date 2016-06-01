FROM ubuntu:wily

MAINTAINER Arif Islam<arif@dreamfactory.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
    git-core curl apache2 php5 php5-common php5-cli php5-curl php5-json php5-mcrypt php5-mysqlnd php5-pgsql php5-sqlite \
    php-pear php5-dev php5-ldap php5-mssql openssl pkg-config libpcre3-dev libv8-dev python nodejs python-pip zip && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/nodejs /usr/bin/node

RUN pip install bunch

RUN pecl install mongodb && \
    echo "extension=mongodb.so" > /etc/php5/mods-available/mongodb.ini && \
    php5enmod mongodb

RUN pecl install v8js-0.1.3 && \
    echo "extension=v8js.so" > /etc/php5/mods-available/v8js.ini && \
    php5enmod v8js

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf && \
    a2enconf servername

RUN rm /etc/apache2/sites-enabled/000-default.conf

RUN php5enmod mcrypt

ADD dreamfactory.conf /etc/apache2/sites-available/dreamfactory.conf
RUN a2ensite dreamfactory
RUN a2dismod mpm_prefork
RUN rm /etc/apache2/mods-available/mpm_prefork.conf
ADD mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
RUN a2enmod mpm_prefork

RUN a2enmod rewrite

# get app src
RUN git clone https://github.com/dreamfactorysoftware/dreamfactory.git /opt/dreamfactory

WORKDIR /opt/dreamfactory

# install packages
RUN composer install

RUN php artisan dreamfactory:setup --no-app-key --db_driver=mysql --df_install=Docker

# Comment out the line above and uncomment these this line if you're building a docker image for Bluemix.  If you're
# not using redis for your cache, change the value of --cache_driver to memcached or remove it for the standard
# file based cache.  If you're using a mysql service, change db_driver to mysql
#RUN php artisan dreamfactory:setup --no-app-key --db_driver=pgsql --cache_driver=redis --df_install="Docker(Bluemix)"

RUN chown -R www-data:www-data /opt/dreamfactory

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# forward request and error logs to docker log collector
RUN ln -sf /dev/stderr /var/log/apache2/error.log

# Uncomment this is you are building for Bluemix and will be using ElephantSQL
#ENV BM_USE_URI=true

EXPOSE 80

CMD ["/docker-entrypoint.sh"]
