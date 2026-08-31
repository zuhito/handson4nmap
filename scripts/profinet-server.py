import os

from scapy.contrib.pnio import ProfinetIO
from scapy.contrib.pnio_dcp import (
    DCPDeviceIDBlock,
    DCPDeviceInstanceBlock,
    DCPDeviceRoleBlock,
    DCPIPBlock,
    DCPManufacturerSpecificBlock,
    DCPNameOfStationBlock,
    ProfinetDCP,
)
from scapy.all import Ether, conf, get_if_addr, get_if_hwaddr, sendp, sniff

IFACE = os.environ.get("PROFINET_IFACE", "eth0")
DCP_MULTICAST = "01:0e:cf:00:00:00"
IDENTIFY_REQUEST = 0xFEFE
IDENTIFY_RESPONSE = 0xFEFF

VENDOR_VALUE = b"Aichi Company AIC-PLC-01"
NAME_OF_STATION = b"aic-plc-01"


def blocks(ip):
    return (
        DCPIPBlock(padding=b"", dcp_block_length=14, block_info=1, ip=ip,
                   netmask="255.255.255.0", gateway=ip.rsplit(".", 1)[0] + ".1")
        / DCPManufacturerSpecificBlock(padding=b"", dcp_block_length=2 + len(VENDOR_VALUE),
                                       device_vendor_value=VENDOR_VALUE)
        / DCPNameOfStationBlock(padding=b"", dcp_block_length=2 + len(NAME_OF_STATION),
                                name_of_station=NAME_OF_STATION)
        / DCPDeviceIDBlock(padding=b"", dcp_block_length=6, vendor_id=0x002A, device_id=0x0105)
        / DCPDeviceRoleBlock(padding=b"", dcp_block_length=4, device_role_details=0x02)
        / DCPDeviceInstanceBlock(padding=b"", dcp_block_length=4, device_instance_high=0,
                                 device_instance_low=100)
    )


def respond(packet):
    dcp = packet[ProfinetDCP]
    reply = (
        Ether(dst=packet[Ether].src, src=get_if_hwaddr(IFACE))
        / ProfinetIO(frameID=IDENTIFY_RESPONSE)
        / ProfinetDCP(service_id=dcp.service_id, service_type=1, xid=dcp.xid,
                      dcp_data_length=90, dcp_blocks=blocks(get_if_addr(IFACE)))
    )
    sendp(reply, iface=IFACE, verbose=False)


conf.iface = IFACE
print("PROFINET DCP responder on %s (%s)" % (IFACE, get_if_addr(IFACE)), flush=True)
sniff(iface=IFACE, filter="ether proto 0x8892 and ether dst " + DCP_MULTICAST,
      lfilter=lambda p: ProfinetIO in p and p[ProfinetIO].frameID == IDENTIFY_REQUEST,
      prn=respond, store=0)
