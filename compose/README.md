# Prozzie compose
This files will be enabled or disabled based on CLI command
`prozzie config enable`. At first, the prozzie only enables the `base.yml`
dockers in compose, and the rest of modules are disabled until you hit that
command.

Be careful because docker compose will NOT resolve variables in
`<connector>.yaml`, with the env file generated in `prozzie config`.
See the `cli/config/<module>.bash` for check variables and how they are
implemented.
