#!/bin/bash

pytest --cov=./ --cov-report=xml
coverage report
