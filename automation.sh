#!/bin/bash -e

if [ -f ~/.bootstrap_complete ]; then
    exit 0
fi

set -x

whoami
sudo apt-get -q update
sudo apt-get -q install python-software-properties
sudo add-apt-repository ppa:mapnik/nightly-2.3 -y
sudo apt-get -q update
sudo apt-get -q install libmapnik-dev mapnik-utils python-mapnik virtualenvwrapper python-dev -y
sudo apt-get -q install gdal-bin=1.10.1+dfsg-5ubuntu1 -y
sudo apt-get -q install libgdal-dev=1.10.1+dfsg-5ubuntu1 -y

virtualenv -q ~/.virtualenvs/tilestache
source ~/.virtualenvs/tilestache/bin/activate

echo "source ~/.virtualenvs/tilestache/bin/activate" >> ~/.bashrc

ln -s /usr/lib/pymodules/python2.7/mapnik ~/.virtualenvs/tilestache/lib/python2.7/site-packages/mapnik

sudo apt-get -q install postgresql-9.3-postgis-2.1 memcached -y
~/.virtualenvs/tilestache/bin/pip install nose coverage python-memcached psycopg2 werkzeug
~/.virtualenvs/tilestache/bin/pip install pil --allow-external pil --allow-unverified pil

cd /srv/tilestache/
~/.virtualenvs/tilestache/bin/pip install -r requirements.txt --allow-external ModestMaps --allow-unverified ModestMaps

~/.virtualenvs/tilestache/bin/pip install --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==1.10.0

sudo sed -i '1i local  test_tilestache  postgres                     trust' /etc/postgresql/9.3/main/pg_hba.conf

sudo /etc/init.d/postgresql restart

sudo -u postgres psql -c "drop database if exists test_tilestache"
sudo -u postgres psql -c "create database test_tilestache"
sudo -u postgres psql -c "create extension postgis" -d test_tilestache
sudo -u postgres ogr2ogr -nlt MULTIPOLYGON -f "PostgreSQL" PG:"user=postgres dbname=test_tilestache" ./examples/sample_data/world_merc.shp

set +x
echo "

touch ~/.bootstrap_complete
