# empty

A scaffold and nothing else. Guards the property the template's own CI check
depends on: **a vault with zero notes lints clean at exit 0 with no findings.**

Every threshold in `lint.sh` has an empty-vault branch — section 6c SKIPs below
10 atoms, section 12 SKIPs with no `extracts/`, section 8's medians are undefined
— and each of those is a place where a future change can make the zero-note case
warn. `memex-init` runs on exactly this state, so a warning here is a warning the
first thing a new fork sees.
