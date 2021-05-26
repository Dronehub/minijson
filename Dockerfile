FROM smokserwis/build:python3

RUN pip install snakehouse Cython satella pytest coverage pytest-cov

ENV DEBUG=1

WORKDIR /tmp/compile
ADD . /tmp/compile/

RUN python setup.py install
RUN rm -rf minijson

CMD ["pytest", "--cov=./", "--cov-report=xml"]
