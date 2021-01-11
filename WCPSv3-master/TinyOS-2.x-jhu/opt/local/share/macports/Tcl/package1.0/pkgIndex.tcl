# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded mp_package 1.0 [list source [file join $dir package.tcl]]
package ifneeded portarchivefetch 1.0 [list source [file join $dir portarchivefetch.tcl]]
package ifneeded portdmg 1.0 [list source [file join $dir portdmg.tcl]]
package ifneeded portdpkg 1.0 [list source [file join $dir portdpkg.tcl]]
package ifneeded portmdmg 1.0 [list source [file join $dir portmdmg.tcl]]
package ifneeded portmpkg 1.0 [list source [file join $dir portmpkg.tcl]]
package ifneeded portpkg 1.0 [list source [file join $dir portpkg.tcl]]
package ifneeded portportpkg 1.0 [list source [file join $dir portportpkg.tcl]]
package ifneeded portrpm 1.0 [list source [file join $dir portrpm.tcl]]
package ifneeded portsrpm 1.0 [list source [file join $dir portsrpm.tcl]]
package ifneeded portunarchive 1.0 [list source [file join $dir portunarchive.tcl]]