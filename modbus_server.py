from pymodbus.datastore import ModbusDeviceContext, ModbusServerContext
from pymodbus.pdu.device import ModbusDeviceIdentification
from pymodbus.server import StartTcpServer

identity = ModbusDeviceIdentification()
identity.VendorName = "Example Automation Co."
identity.ProductCode = "MB-TEST-1"
identity.MajorMinorRevision = "1.0.0"

StartTcpServer(
    ModbusServerContext(devices=ModbusDeviceContext(), single=True),
    identity=identity,
    address=("0.0.0.0", 502),
)
