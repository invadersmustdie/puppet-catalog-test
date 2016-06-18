#!/bin/bash

rake generate_test_matrix

bash run-all-tests|tee last-test.log
