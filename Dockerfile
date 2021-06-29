FROM python:3.5
RUN apt-get update && \
    apt-get install -y patchelf
RUN python -m pip install Cython pytest coverage pytest-cov auditwheel doctor-wheel twine

ENV DEBUG=1

WORKDIR /tmp/compile
ADD . /tmp/compile/

RUN python setup.py install && \
    chmod ugo+x /tmp/compile/tests/test.sh

CMD ["/tmp/compile/tests/test.sh"]
