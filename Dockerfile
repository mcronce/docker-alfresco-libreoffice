FROM fedora as version_discoverer
ENV LIBREOFFICE_DOWNLOAD_MIRROR="http://download.documentfoundation.org/libreoffice/stable"

RUN dnf install -y python2-pip
RUN pip install --no-cache-dir mechanize cssselect lxml packaging

RUN mkdir /app
ADD assets/find_latest_version /app/
RUN \
	( \
		set -ex; \
		echo "LIBREOFFICE_DOWNLOAD_MIRROR=\"${LIBREOFFICE_DOWNLOAD_MIRROR}\""; \
		echo "LIBREOFFICE_VERSION=\"$(/app/find_latest_version "${LIBREOFFICE_DOWNLOAD_MIRROR}")\""; \
	) > /app/latest_versions.env

FROM centos:centos7
MAINTAINER Jeremie Lesage <jeremie.lesage@gmail.com>

COPY --from=version_discoverer /app/latest_versions.env /root/

RUN \
    yum install -y fontconfig libSM libICE libXrender libXext cups-libs cairo \
                   xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi ghostscript-fonts \
                   gnu-free-sans-fonts gnu-free-serif-fonts  liberation-serif-fonts \
                   liberation-sans-fonts liberation-mono-fonts freetype open-sans-fonts \
                   libXinerama \
    && yum clean all

ENV HOST="0.0.0.0" \
    PORT="8100" \
    LIBREOFFICE_HOME="/opt/libreoffice5.4" \
    PATH="$LIBREOFFICE_HOME/program:$PATH"

RUN \
	set -ex && \
	. /root/latest_versions.env && \
	LIBREOFFICE_RPM_TGZ="LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz" && \
	LIBREOFFICE_RPM_DIR="LibreOffice_${LIBREOFFICE_VERSION}.*_Linux_x86-64_rpm" && \
	curl -L "${LIBREOFFICE_DOWNLOAD_MIRROR}/${LIBREOFFICE_VERSION}/rpm/x86_64/${LIBREOFFICE_RPM_TGZ}" | tar xz && \
	yum install -y \
      ${LIBREOFFICE_RPM_DIR}/RPMS/libreoffice5.4-*.rpm \
      ${LIBREOFFICE_RPM_DIR}/RPMS/libobasis5.4-*.rpm \
    && yum clean all \
    && rm -rf ${LIBREOFFICE_RPM_DIR} ${LIBREOFFICE_RPM_TGZ} \
    && useradd -ms /bin/bash libreoffice \
    && chown -R libreoffice:libreoffice $LIBREOFFICE_HOME

WORKDIR $LIBREOFFICE_HOME

EXPOSE ${PORT}

#COPY assets/sofficerc /etc/libreoffice/sofficerc
COPY assets/entrypoint.sh /$LIBREOFFICE_HOME/
RUN chmod +x /opt/libreoffice5.4/entrypoint.sh

ENTRYPOINT ["/opt/libreoffice5.4/entrypoint.sh"]
CMD ["run"]

