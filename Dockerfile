FROM smokserwis/build:python3

RUN pip install Cython pytest coverage pytest-cov

ENV DEBUG=1

WORKDIR /tmp/compile
ADD . /tmp/compile/

RUN python setup.py install && \
    chmod ugo+x /tmp/compile/tests/test.sh

CMD ["/tmp/compile/tests/test.sh"]
