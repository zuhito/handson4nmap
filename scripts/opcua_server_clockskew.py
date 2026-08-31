from datetime import datetime, timedelta

from opcua import Server
from opcua.ua import uaprotocol_auto

FIXED_TIME = datetime(2028, 11, 15, 0, 0, 0)


class FixedDateTime(datetime):
    """Reports a constant time so the clock skew is always the same."""

    @classmethod
    def utcnow(cls):
        return FIXED_TIME

    @classmethod
    def now(cls, tz=None):
        return FIXED_TIME


# ResponseHeader stamps every reply with datetime.utcnow() from this module.
uaprotocol_auto.datetime = FixedDateTime

server = Server()
server.set_endpoint("opc.tcp://0.0.0.0:4840/freeopcua/server/")
server.set_server_name("Aichi Company OPC UA Server")

idx = server.register_namespace("http://aichi.example/plc/")
device = server.nodes.objects.add_object(idx, "AIC-PLC-01")
device.add_variable(idx, "Temperature", 25.0)

server.start()
