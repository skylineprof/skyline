import logging

import lib.models_gen.messages_pb2 as m

logger = logging.getLogger(__name__)


class MessageHandler:
    def __init__(self, message_sender):
        self._message_sender = message_sender

    def _handle_analyze_request(self, message, address):
        logger.info('From (%s:%d) received: %s', *address, message.source_code)
        self._message_sender.send_analyze_response(
            'Hello world back!', address)

    def handle_message(self, raw_data, address):
        try:
            message = m.PluginMessage()
            message.ParseFromString(raw_data)
            logger.debug('Received message from (%s:%d).', *address)

            message_type = message.WhichOneof('payload')
            if message_type is None:
                logger.warn('Received empty message from (%s:%d).', *address)
                return

            if message_type == 'analyze_request':
                self._handle_analyze_request(
                    getattr(message, message_type), address)
            else:
                # If the protobuf was compiled properly, this block should
                # never be reached.
                raise AssertionError(
                    'Invalid message type "{}".'.format(message_type))
        except:
            logger.exception(
                'Processing message from (%s:%d) resulted in an exception.',
                *address,
            )