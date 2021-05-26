FROM smokserwis/build:python3

RUN pip install snakehouse Cython satella pytest

ENV DEBUG=1

WORKDIR /tmp/compile
ADD minijson /tmp/compile/minijson
ADD setup.py /tmp/compile/setup.py
ADD README.md /tmp/compile/README.md
ADD setup.cfg /tmp/compile/setup.cfg

RUN python setup.py install

WORKDIR /tmp

ADD tests /tmp/tests

CMD ["pytest"]
