#!/bin/sh

stress-ng --cpu "$(nproc)" --cpu-load 100 --timeout 15s --metrics-brief