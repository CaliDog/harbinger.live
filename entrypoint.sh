#!/usr/bin/env bash

cd harbinger-server

mix deps.get

mix run --no-halt
