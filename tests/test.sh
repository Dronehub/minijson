#!/bin/bash

pytest --cov=./ --cov-report=xml -vv
coverage report
