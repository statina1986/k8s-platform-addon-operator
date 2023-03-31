import logging
from pythonjsonlogger import jsonlogger
from os import environ

level = environ.get('LOG_LEVEL', 'info').upper()

logger = logging.getLogger(__name__)
logger.setLevel(level)

# create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(level)

# create formatter
formatter = jsonlogger.JsonFormatter()

# add formatter to ch
ch.setFormatter(formatter)

# add ch to logger
logger.addHandler(ch)