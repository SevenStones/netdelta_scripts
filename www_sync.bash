#!/usr/bin/env bash
rsync -azpr --progress --exclude-from=config/www-excludes.txt /home/iantibble/jango/ndwww/ netdelta.io:/home/iantibble/netdelta_sites/ndwww/

