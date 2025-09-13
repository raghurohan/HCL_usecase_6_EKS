# policy/policy.rego
package main

# --- helpers ---------------------------------------------------------------

# resource_change that matches an aws_vpc being created/updated (not no-op)
vpc_change := rc {
  rc := input.resource_changes[_]
  rc.type == "aws_vpc"
  rc.change.actions[_] != "no-op"
}

# get the CIDR (some modules use cidr_block key)
vpc_cidr(rc, cidr) {
  cidr := rc.change.after.cidr_block
}
vpc_cidr(rc, cidr) {
  cidr := rc.change.after.cidr
}

# helper: is cidr private (RFC1918)
is_private_cidr(cidr) {
  net.cidr_contains("10.0.0.0/8", cidr)
}
is_private_cidr(cidr) {
  net.cidr_contains("172.16.0.0/12", cidr)
}
is_private_cidr(cidr) {
  net.cidr_contains("192.168.0.0/16", cidr)
}

# helper: check tag exists (project/environment)
has_tag(rc, key) {
  # if tags map exists and the key has a value, this makes true
  rc.change.after.tags[key]
}

# --- deny rules -----------------------------------------------------------

# 1) VPC must use RFC1918 private CIDR
deny contains msg if {
  rc := vpc_change
  vpc_cidr(rc, cidr)
  not is_private_cidr(cidr)
  # rc.address is available in resource_changes, fallback to type/name if missing
  addr := rc.address
  msg := sprintf("VPC '%v' uses non-private CIDR '%v' — use RFC1918 ranges (10/8,172.16/12,192.168/16).", [addr, cidr])
}

# 2) VPC must have 'project' tag
deny contains msg if {
  rc := vpc_change
  not has_tag(rc, "project")
  addr := rc.address
  msg := sprintf("VPC '%v' missing required tag: 'project'. Add tags = { project = \"<name>\" }", [addr])
}

# 3) VPC must have 'environment' tag
deny contains msg if {
  rc := vpc_change
  not has_tag(rc, "environment")
  addr := rc.address
  msg := sprintf("VPC '%v' missing required tag: 'environment'. Add tags = { environment = \"dev|stg|prod\" }", [addr])
}

# --- optional: warn about peering flag mismatch --------------------------------
# If a module variable is set (is_peering_required=true) but no peering resource found,
# we emit a warning (best-effort - plan JSON structures vary).
warn_contains msg if {
  some mc_name
  # look for module calls in configuration (if present) to see module var settings
  conf := input.configuration
  conf != null
  mc := conf.root_module.module_calls[mc_name]
  mc_name == "vpc"                          # change if your call name differs
  # expressions may be structured; attempt to read a constant expression
  expr := mc.expressions.is_peering_required
  expr != null
  # check expression has a constant boolean true
  expr.constant.value == true
  # no guarantee to find peering resources; best-effort check over resource_changes
  not some rc2 {
  rc2 := input.resource_changes[_]
  rc2.type == "aws_vpc_peering_connection"  # provider-specific; optional
  msg := "Module 'vpc' requested peering (is_peering_required=true) but plan contains no aws_vpc_peering_connection resources. Verify the module or set the flag appropriately."
  }
}
