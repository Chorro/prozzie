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

You can check that messages are properly delivered using `prozzie kafka consume testtopic`.
