#!/bin/bash

rsync -avP -e ssh public/ dennis@fizz.rift.lan:/home/www/dennis.io/blog.dennis.io/
