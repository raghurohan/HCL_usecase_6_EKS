package main

import future.keywords.in

# --- helpers ---------------------------------------------------------------

# A set of resource_changes that match an aws_vpc being created or updated.
vpc_changes[rc] if {
    rc := input.resource_changes[_]
    rc.type == "aws_vpc"
    rc.change.actions[_] != "no-op"
}

# Get the CIDR - using proper function syntax
vpc_cidr_block(rc) = cidr if {
    cidr := rc.change.after.cidr_block
}

vpc_cidr(rc) = cidr if {
    cidr := rc.change.after.cidr
}

# Helper: check if a CIDR is within private RFC1918 address space.
is_private_cidr(cidr) if {
    net.cidr_contains("10.0.0.0/8", cidr)
}
is_private_cidr(cidr) if {
    net.cidr_contains("172.16.0.0/12", cidr)
}
is_private_cidr(cidr) if {
    net.cidr_contains("192.168.0.0/16", cidr)
}

# Helper: check that a specific tag key exists and has a value.
has_tag(rc, key) if {
    rc.change.after.tags[key] != null
}

# Helper: get resource address safely
get_address(rc) = addr if {
    addr := rc.address
}
get_address(rc) = addr if {
    not rc.address
    addr := sprintf("%s.%s", [rc.type, rc.name])
}

# --- deny rules -----------------------------------------------------------

deny[msg] if {
    rc := vpc_changes[_]
    cidr := vpc_cidr_block(rc)
    not is_private_cidr(cidr)
    addr := get_address(rc)
    msg := sprintf("VPC '%v' uses non-private CIDR '%v' — use RFC1918 ranges (10/8, 172.16/12, 192.168/16).", [addr, cidr])
}

deny[msg] if {
    rc := vpc_changes[_]
    not has_tag(rc, "project")
    addr := get_address(rc)
    msg := sprintf("VPC '%v' missing required tag: 'project'. Add tags = { project = \"<name>\" }", [addr])
}

deny[msg] if {
    rc := vpc_changes[_]
    not has_tag(rc, "environment")
    addr := get_address(rc)
    msg := sprintf("VPC '%v' missing required tag: 'environment'. Add tags = { environment = \"dev|stg|prod\" }", [addr])
}

# --- optional: warn about peering flag mismatch --------------------------------
# If a module variable is set (is_peering_required=true) but no peering resource found,
# we emit a warning. This is a best-effort check as plan structures can vary.

# Helper to check if a VPC peering resource exists in the plan.
peering_resource_exists if {
    some i
    rc := input.resource_changes[i]
    rc.type == "aws_vpc_peering_connection"
    rc.change.actions[_] != "no-op"
}

