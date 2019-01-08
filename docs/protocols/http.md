---
---

# JSON/HTTP

Here you can send JSON data over HTTP using curl directly (or similar http
client) to port 7980:

```bash
$ curl -d '{"test":1,"timestamp":1518086046}' \
localhost:7980/v1/data/testtopic
```

You can batch JSONs and prozzie will split JSON messages by itself:

```bash
$ curl -d \
'{"test":1,"timestamp":1518086046}{"test":2,"timestamp":1518086047}' \
localhost:7980/v1/data/testtopic
```

You can check that messages are properly delivered using
`prozzie kafka consume testtopic`.

# The http2k connector
Please enable the connector using `prozzie config setup http2k`. It will ask
you SSL/TLS related questions, that you could leave blank if you don't want to
use them.

# SSL/TLS
## Quick SSL/TLS setup
Here you have some instructions if you want to test the http2k TLS
implementation quickly. It should be easy to change the individual steps, like
obtaining the key/certificate pair or adapt the HTTP client option from curl.

### Generate key/certificate pair

To generate a key-certificate pair, you can use the next command. You may need
to adapt it depending on your openssl installation:

```bash
$ openssl req \
-newkey rsa:2048 -nodes\
-keyout 'key.pem' \
-x509 -days 3650\
-subj "/CN=localhost/"
-extensions SAN \
-config <(cat /etc/ssl/openssl.cnf - <<'EOF'
[req]
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ SAN ]
subjectAltName=DNS:localhost
EOF
) \
-out 'certificate.pem'
```

Change every parameter at convenience, taking into account:
- Name of key/certificate produced (`-keyout`, `out`)
- Validity in days (`-days`)
- Exported common names and alternative names. Need to match with client
  requests.
- `openssl.cnf` and heredoc (lines between `EOF`) content.

You need to generate another key/certificate pair if you want to use the
client authentication mechanism too.

After that, answer the questions of command `prozzie config setup http2k`.

### Testing with curl
You can make requests using https if you have configured certificate common
name or alternate name:

```bash
curl -v -d '{"test":1}' https://localhost:7980/v1/data/abc
```

Or ignore the certificate's common name with `-k` option:

```bash
curl -k -v -d '{"test":1}' https://localhost:7980/v1/data/abc
```

If you have set up a client verification CA, you will need to use the generated
client key/certificate pair with the `--key` and `--cert` options:

```bash
curl -k -v -d '{"test":1}' \
--key client-key.pem \
--cert client-certificate.pem \
https://localhost:7980/v1/data/abc
```

# Variables
You can set these variables in the environment before calling
`prozzie config setup`, use them on `prozzie config set http2k VAR=VAL`, or delete them with `prozzie config set http2k VAR=`.

<table>
<tr><th>ENV</th><th>Description</th></tr>
<tr>
    <td>HTTP_TLS_KEY_FILE</td>
    <td>Private key to use (blank for plain http)</td>
</tr>
<tr>
    <td>HTTP_TLS_CERT_FILE</td>
    <td>Certificate to export (blank for plain http)</td>
</tr>
<tr>
    <td>HTTP_TLS_CLIENT_CA_FILE</td>
    <td>Certificate Authority for clients (blank for no client verification)
    </td>
</tr>
<tr>
    <td>HTTP_TLS_KEY_PASSWORD</td>
    <td>Password to decrypt key (blank for no password)</td>
</tr>
</table>
