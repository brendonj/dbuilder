{% extends "apt_based.dockerfile" %}

{% block repository_setup %}
{%- if arch in ['i386', 'amd64'] %}
RUN /bin/sed -i 's/main/main restricted universe/' /etc/apt/sources.list
{%- else %}
RUN echo "deb http://ports.ubuntu.com/ubuntu-ports {{ tag }} main restricted universe" >> /etc/apt/sources.list && \
echo "deb http://ports.ubuntu.com/ubuntu-ports {{ tag }}-updates main restricted universe" >> /etc/apt/sources.list && \
echo "deb http://ports.ubuntu.com/ubuntu-ports {{ tag }}-security main restricted universe" >> /etc/apt/sources.list
{%- endif %}
{% endblock %}
