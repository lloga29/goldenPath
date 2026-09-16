<!-- This content is inserted before terraform-docs generated sections. -->

## Security and operational expectations

- Prefer encryption and private access by default where the provider supports them.
- Enable logging/telemetry when the module exposes the capability.
- Require ownership and cost metadata according to organization policy.
- Treat provider-specific differences explicitly; this reference does not guarantee identical behavior across AWS, Azure, and GCP.
- Review lifecycle and deletion behavior before production adoption.

## Version pinning

Production consumers should pin an immutable module release rather than follow a moving branch.
