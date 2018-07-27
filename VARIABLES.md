<table><tr><th>ENV</th><th>Default</th><th>Description</th></tr>
<tr><th colspan="3" align="center">f2k</th></tr>
<tr><td>NETFLOW_PROBES</td><td>(No default)</td><td>JSON object of NF probes (It's recommend to use env var) </td></tr>
<tr><td>NETFLOW_KAFKA_TOPIC</td><td>flow</td><td>Topic to produce netflow traffic? </td></tr>
<tr><th colspan="3" align="center">linux</th></tr>
<tr><td>INTERFACE_IP</td><td>(No default)</td><td>Introduce the IP address</td></tr>
<tr><td>CLIENT_API_KEY</td><td>(No default)</td><td>Introduce your client API key</td></tr>
<tr><td>PREFIX</td><td>/usr/local</td><td>Where do you want install prozzie?</td></tr>
<tr><td>ZZ_HTTP_ENDPOINT</td><td>(No default)</td><td>Introduce the data HTTP endpoint URL</td></tr>
<tr><th colspan="3" align="center">sfacctd</th></tr>
<tr><td>SFLOW_KAFKA_TOPIC</td><td>sflow</td><td>Topic to produce sflow traffic</td></tr>
<tr><td>SFLOW_RENORMALIZE</td><td>true</td><td>Normalize sflow based on sampling</td></tr>
<tr><td>SFLOW_AGGREGATE</td><td>cos, etype, src_mac, dst_mac, vlan, src_host, 	dst_host, src_mask, dst_mask, src_net, dst_net, proto, tos, src_port, 	dst_port, tcpflags, src_as, dst_as, as_path, src_as_path,</td><td></td></tr>
</table>
