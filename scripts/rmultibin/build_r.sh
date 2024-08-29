#! /bin/bash

# -- set up working directories
echo "--- set up script scaffolding"
mkdir -p /sources/R /builds /logs/R/rmultibin/builds


# -- process R version
#
#

# -- R source repository
REPO=https://cran.r-project.org/src/base/R-4


for BUILD_VER in $(grep "^[^#;]" /opt/openapx/config/rmultibin/r_versions | tr '\n' ' '); do

  echo "-- build R version ${BUILD_VER}"

  # -- download source	

  XSOURCE=R-${BUILD_VER}.tar.gz
  URL=${REPO}/${XSOURCE}

  echo "   downloading ${URL}"
  wget --no-check-certificate --quiet --directory-prefix=/sources/R ${URL}

  _MD5=($(md5sum /sources/R/${XSOURCE})) 
  _SHA256=($(sha256sum /sources/R/${XSOURCE}))

  echo "   ${XSOURCE} (MD5 ${_MD5} / SHA-256 ${_SHA256})"

  unset _MD5
  unset _SHA256


  # -- set up build area
  echo "   set up build area"

  mkdir -p /builds/R-${BUILD_VER} /builds/sources

  # -- unpack tar
  echo "   extract sources"

  cd /builds/sources
  tar -xf /sources/R/R-${BUILD_VER}.tar.gz

  find /builds/sources/R-${BUILD_VER}/ -type f -exec md5sum {} + > /logs/R/rmultibin/builds/R-${BUILD_VER}-sources.md5
  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-sources.md5

  find /builds/sources/R-${BUILD_VER}/ -type f -exec sha256sum {} + > /logs/R/rmultibin/builds/R-${BUILD_VER}-sources.sha256
  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-sources.sha256



  # -- configure
  echo "   configure R ${BUILD_VER}"

  cd /builds/R-${BUILD_VER}

  ../sources/R-${BUILD_VER}/configure --prefix=/opt/R/${BUILD_VER} \
  	                              --enable-R-shlib \
				      --with-blas \
				      --with-lapack \
				      --with-recommended-packages=no > /logs/R/rmultibin/builds/R-${BUILD_VER}-config.log 2>&1

  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-config.log




  # -- build 
  echo "   build R ${BUILD_VER}"
  make > /logs/R/rmultibin/builds/R-${BUILD_VER}-make.log 2>&1

  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-make.log 


  # -- check build
  echo "   check R ${BUILD_VER} build"

  make check-all > /logs/R/rmultibin/builds/R-${BUILD_VER}-check.log 2>&1

  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-check.log


  # -- install build 
  echo "-- install R ${BUILD_VER}"

  make install > /logs/R/rmultibin/builds/R-${BUILD_VER}-install.log 2>&1

  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-install.log


  find /opt/R/${BUILD_VER} -type f -exec md5sum {} + > /logs/R/rmultibin/builds/R-${BUILD_VER}-install.md5
  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-install.md5

  find /opt/R/${BUILD_VER} -type f -exec sha256sum {} + > /logs/R/rmultibin/builds/R-${BUILD_VER}-install.sha256
  gzip -9 /logs/R/rmultibin/builds/R-${BUILD_VER}-install.sha256


  # -- initiate site library

  echo "-- initiate R ${BUILD_VER} site library"

  # identify lib directory .. sometime it is lib .. on others it is lib64 ... use ../R/library/base/DESCRIPTION (package) as trigger
  RLIBX=$( find /opt/R/${BUILD_VER} -type f -name DESCRIPTION | grep "/R/library/base/DESCRIPTION$" | awk -F/ '{print $5}' )


  mkdir -p /opt/R/${BUILD_VER}/${RLIBX}/R/site-library


  # -- secure the install location
  echo "-- secure R ${BUILD_VER} installation"

  find /opt/R/${BUILD_VER} -type f -exec chmod u+r-wx,g+r-wx,o+r-wx {} \;
  find /opt/R/${BUILD_VER} -type d -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;

  # -- open up site-library for writing
  chmod u+rwx,g+rwx,o+rx-w /opt/R/${BUILD_VER}/${RLIBX}/R/site-library

  # -- make R executable again 
  find /opt/R/${BUILD_VER}/${RLIBX}/R/bin -type f -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;
  chmod u+rx-w,g+rx-w,o+rx-w /opt/R/${BUILD_VER}/bin/*

  echo "-- R ${BUILD_VER} build and install completed"

done


# -- clean up after build
echo "-- clean up"
rm -Rf /sources /builds

