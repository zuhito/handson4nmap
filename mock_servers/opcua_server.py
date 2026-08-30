from opcua import Server

server = Server()
server.set_endpoint("opc.tcp://0.0.0.0:4840/freeopcua/server/")
server.set_server_name("Aichi Company OPC UA Server")

idx = server.register_namespace("http://aichi.example/plc/")
device = server.nodes.objects.add_object(idx, "AIC-PLC-01")
device.add_variable(idx, "Temperature", 25.0)

server.start()
