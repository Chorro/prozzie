---
---
# Prozzie

[Prozzie](http://github.com/wizzie-io/prozzie) is the main entry point for the
data plane of [Wizzie Data Platform](http://wizzie.io/).

Under the hoods, prozzie is just a docker-compose file that provides you the
basics for sending the data events to WDP: authentication, encryption,
homogenization and a flexible kafka buffer for back-pressure and local data
persistence.

It provides out-of-the-box support for **json** over kafka, http POSTs, and
mqtt, and it supports others such as netflow, snmp, and json over mqtt with a
small configuration.

Please navigate through the different sections to know how to
[Install](installation/Installation) or configure prozzie.

## License

Copyright 2018-2019 Wizzie S.L.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Prozzie documentation license

Permission is granted to copy, distribute and/or modify this
document under the terms of the GNU Free Documentation License,
Version 1.3 or any later version published by the Free Software
Foundation; with no Invariant Sections, no Front-Cover Texts, and
no Back-Cover Texts.  A copy of the license is included in the
page [GNU Free Documentation License](LICENSE.html).
