# PKGSRC Multi-Release Deployment Guide

## Overview

This guide provides a parameterized PKGSRC framework supporting scientific computing requirements across Darwin, NetBSD, and Linux platforms. The system maintains multiple concurrent package environments with unique LOCALBASE paths, security hardening, vulnerability tracking, and certification management.

PKGSRC provides a standard for managing release cycles, dependencies, updates, and building packages across multiple OS. The default bootstrap guide is intended for general use, while this bootstrap guide leverages the available parameters for deployments with complex requirements, such as retention of specific release sets, while newer cycles are installed under their own prefix.

**Key Features:**
- Multi-platform bootstrap (Darwin/macOS, NetBSD, Linux)  
- Concurrent current/stable source trees with CVS management
- Unique versioned LOCALBASE paths with encoded metadata
- Security-hardened configurations with runtime vulnerability scanning
- Package certification, lifecycle management, and integrity verification
- Cross-compilation support with toolchain integration
- Dedicated build account isolation with unprivileged operations

## Path Conventions & Environment Variables

### Core Path Structure
```
/opt (Darwin) or /usr (NetBSD/Linux)
+-- pkgsrc-current/          # HEAD development source
+-- pkgsrc-stable/           # Quarterly release source  
+-- dist/                    # Source distribution cache (DISTDIR)
+-- pkg-2025Q1-663c7-*/      # Versioned install prefix (LOCALBASE)
+-- packages-*/              # Built binary packages (PACKAGES)

/tmp (Darwin/NetBSD) or /dev/shm (Linux)
+-- work-pkg-*/              # Build workspace (WRKOBJDIR)
```

### Environment Variables

Typical user environment, from avaiable installed pkgsrc releases, the user selects their desired LOCALBASE and configures the release availability through their PATH varable.

In this PKGSRC framework, selecting the release is a manual step, to ensure the user has the specific software versions expected for their workflow.

```bash
# Detect platform and set path
export OS=$(uname)
case "$OS" in *BSD|Linux) pre=/usr ;; Darwin) pre=/opt ;; esac
# identify available release prefix and add them to user env profile: ls -d1 $pre/pkg-*/{sbin,bin}
test -d /opt/pkg-2024Q4-67799-Darwin_22.6.0_arm64/bin  && PATH="$_":$PATH
test -d /opt/pkg-2024Q4-67799-Darwin_22.6.0_arm64/sbin && PATH="$_":$PATH
```

#### LOCALBASE assignment
LOCALBASE setting is conditional on scenario

* Add packages packages to an existing LOCALBASE
```bash
# Set or discover existing source branch and install prefix
export pkgsrc="$pre/pkgsrc-stable"
export pkgtag="pkgsrc-2025Q1" # manual set
read pkgtag < <(sed 's/^T//' $pkgsrc/CVS/Tag) # tag discovery
# OR: export pkgsrc="$pre/pkgsrc-current" pkgtag="HEAD"

# Set existing LOCALBASE and pkgrev
read REPLY < <(sed "s,/bin/bmake,," < <(which bmake))
[ -d "$REPLY" ] && { export LOCALBASE="$REPLY" PKG_DBDIR="$REPLY/pkgdb"
read pkgrev < <(basename "$LOCALBASE") ;}
```

* New LOCALBASE bootstrap
```bash
# Generate new revision, timestamp, bootstrap identifier, and set LOCALBASE
read pkgtag < <(awk '{m=$2-3;y=$1; if(m<=0){m+=12;y--} print "pkgsrc-" y "Q" (int((m-1)/3)+1)}' < <(date "+%Y %m"))
read -d '' now < <(awk -v nd=5 -v ts=$(date +%s) 'BEGIN{s=32-(4*nd);printf"%0"nd"x\n",int(ts/2^s)}') || true
pkgrev=${pkgtag/pkgsrc/pkg}-${now}-$(uname -msr | tr ' ' '_')
export LOCALBASE="$pre/$pkgrev" PKG_DBDIR="$LOCALBASE/pkgdb"
```

#### Configuration Variables for Build 

When setting build env, ensure source tag ($pkgtag) matches prefix ($LOCALBASE) indication.

**Patterns**
  * get source and set $pkgsrc in the environment
  * add $LOCALBASE/{bin,sbin} to $PATH after release bootstrap
  * for package build, apply `which bmake` to determine $LOCALBASE from $PATH
  * discover $pkgtag from $pkgsrc checkout, prior to source update
  * use $LOCALBASE to determine other build paramaters, for package builds
  * set a new $pkgtag and $LOCALBASE prefix, to bootstrap and install a new release

## Quick Start

### Environment Setup (All Platforms)

LOCALBASE selects to the installed release prefix and underpins all other build parameters, and release runtime env, eg:

```bash
$LOCALBASE/etc/mk.conf                    # compile options file produced by bootstrap-pkgsrc
$LOCALBASE/etc/pkgin/repositories.conf    # package repositories list, for binary install and updates
$LOCALBASE/etc/openssl/openssl.cnf        # OpenSSL package configuration file
```

#### Detect platform and set base paths

```bash
export OS=$(uname)
case "$OS" in *BSD|Linux) pre=/usr ;; Darwin) pre=/opt ;; esac
case "$OS" in *BSD|Darwin) tmp=/tmp ;; Linux) tmp=/usr/shm ;; esac

export tmp pre pkgsrc pkgrev
export DISTDIR="$pre/dist"                 # Shared upstream source cache
export LOCALBASE="$pre/$pkgrev" 
export PACKAGES="$pkgsrc/packages-$pkgrev" # Binary package output separated by install prefix
export OBJMACHINE="defined"                # Enable object directory separation, for cross-builds
export WRKOBJDIR="$tmp/work-${pkgrev}"     # Build workspace, for platform-specific performance
```

## Platform-Specific Bootstrap

### Build Account Setup

Packages are built from an unprivileged dedicated user account:
```bash
# Create dedicated package build account for isolation
# Leverages sudo for unprivileged implementation
sudo useradd -m -s /bin/bash pkgbuild
sudo -u pkgbuild -i  # Switch to build account
```

### Darwin/macOS

```bash
# Prerequisites and SDK detection
softwareupdate --history
xcode-select -v
xcrun -v --show-sdk-version

# CPU core detection - use physical cores
read cores < <(sysctl -n hw.physicalcpu)

# Prepare target directory with sudo for unprivileged bootstrap
[ -d "$LOCALBASE" ] && { echo "ERROR: Target exists: '$LOCALBASE'" >&2 ; return 1 ;} \
  || sudo mv $(mktemp -d) $LOCALBASE

# Update source if exists with CVS filtering
[ -f "$pkgsrc/CVS/Tag" ] && (
    echo "Updating PKGSRC source..."
    cd "$pkgsrc"
    read -d '' Tag < <(sed 's/^T//' < CVS/Tag) || true
    { date ; pwd ; cvs -q upd -dP -r $Tag . 2>&1 ;} | sed '/\/work$/d' | tee -a ./cvs.log )

# Bootstrap LOCALBASE
cd "$pkgsrc/bootstrap"
[ -d work ] && rm -rf work
./bootstrap \
    --prefix "$LOCALBASE" \
    --workdir "$WRKOBJDIR" \
    --make-jobs $cores \
    --unprivileged \
    --prefer-pkgsrc yes 2>&1 | tee -a "$pkgsrc/bootstrap.log"
```

### NetBSD

```bash
# CPU core detection
read cores < <(sysctl -n hw.ncpu)

# Prepare target directory with sudo for unprivileged bootstrap
[ -d "$LOCALBASE" ] && { echo "ERROR: Target exists: '$LOCALBASE'" >&2 ; return 1 ;} \
  || sudo mv $(mktemp -d) $LOCALBASE

# Bootstrap with NetBSD-specific settings
cd "$pkgsrc/bootstrap"
[ -d work ] && rm -rf work
./bootstrap \
    --prefix "$LOCALBASE" \
    --workdir "$WRKOBJDIR" \
    --make-jobs $cores \
    --unprivileged \
    --prefer-pkgsrc yes 2>&1 | tee -a "$pkgsrc/bootstrap.log"
```

### Linux

```bash
# CPU core detection
read cores < <(nproc)

# Prepare target directory with sudo for unprivileged bootstrap
[ -d "$LOCALBASE" ] && { echo "ERROR: Target exists: '$LOCALBASE'" >&2 ; return 1 ;} \
  || sudo mv $(mktemp -d) $LOCALBASE

# Ensure /dev/shm workspace exists
[ -d "$WRKOBJDIR" ] || mkdir -p "$WRKOBJDIR" || return 1

# Bootstrap with Linux-specific optimizations
cd "$pkgsrc/bootstrap"
[ -d work ] && rm -rf work
./bootstrap \
    --prefix "$LOCALBASE" \
    --workdir "$WRKOBJDIR" \
    --make-jobs $cores \
    --unprivileged \
    --prefer-pkgsrc yes 2>&1 | tee -a "$pkgsrc/bootstrap.log"
```


## Security Configuration

### Hardened mk.conf
After bootstrap, append to `$LOCALBASE/etc/mk.conf`:

```make
# Build paths derived from LOCALBASE
DISTDIR=    $DISTDIR
WRKOBJDIR=  $WRKOBJDIR  
PACKAGES=   $PACKAGES
OBJMACHINE= defined

# Security and vulnerability management
ALLOW_VULNERABLE_PACKAGES=  NO

# Hardening options (https://www.netbsd.org/docs/pkgsrc/hardening.html)
PKGSRC_USE_STACK_CHECK?=    yes     # Stack boundary verification
PKGSRC_USE_FORTIFY?=        yes     # Buffer overflow protection  
PKGSRC_USE_SSP?=            all     # Stack protector (default: strong)
# PKGSRC_MKPIE=             yes     # Position-independent executables
# PKGSRC_USE_RELRO?=        partial # Relocation read-only (full slows loading)

# Reproducible builds for bit-for-bit verification
# When same source built with same compiler/flags/environment
# Benefits: Security verification, supply chain integrity, trust transparency

# License acceptance
ACCEPTABLE_LICENSES+= gnu-agpl-v3
ACCEPTABLE_LICENSES+= esdl-license

# Build optimization
MAKE_JOBS=              $cores      # Platform-detected cores
PKG_DEVELOPER?=         yes
PKG_DEFAULT_OPTIONS+=   -x11        # Disable X11 by default

# Package-specific security options
PKG_OPTIONS.ffmpeg6+=   -x11
PKG_OPTIONS.SDL2+=      -x11
```

## Vulnerability Management

### Build-Time Vulnerability Tracking
```
# Update vulnerability database before any package operations
$LOCALBASE/sbin/pkg_admin -K $LOCALBASE/pkgdb fetch-pkg-vulnerabilities

# Verify packages during build
cd $pkgsrc/category/package
bmake audit-packages      # Check for known vulnerabilities
```

### Runtime Vulnerability Monitoring
```
# Daily vulnerability report generation
cat > /usr/local/bin/pkgsrc-vuln-report << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

read LOCALBASE < <(which bmake | sed 's,/bin/bmake,,')
read PKG_DBDIR < <($LOCALBASE/bin/bmake -f- show-var VARNAME=PKG_DBDIR <<< '.include "../../mk/bsd.prefs.mk"')

# Update vulnerability database
$LOCALBASE/sbin/pkg_admin -K $PKG_DBDIR fetch-pkg-vulnerabilities

# Generate vulnerability report
{
    echo "PKGSRC Vulnerability Report - $(date)"
    echo "LOCALBASE: $LOCALBASE"
    echo "========================================="
    $LOCALBASE/sbin/pkg_admin -K $PKG_DBDIR audit
} | mail -s "PKGSRC Vulnerability Report $(hostname)" root@localhost
EOF

chmod +x /usr/local/bin/pkgsrc-vuln-report

# Schedule daily execution
echo "0 6 * * * /usr/local/bin/pkgsrc-vuln-report" | crontab -
```

## Package Management Workflow

### Initial Setup with Integrity Verification

```
# Set up environment - LOCALBASE determined from bmake location
export PATH="$LOCALBASE/bin:$LOCALBASE/sbin:$PATH"
read LOCALBASE < <(which bmake | sed 's,/bin/bmake,,')
export LOCALBASE

# Install package management tools
cd $pkgsrc/pkgtools/pkg_summary-utils && bmake clean package package-install
cd $pkgsrc/pkgtools/pkgin && bmake clean package package-install

# Configure package repository
read -d '' PACKAGES < <(bmake show-var VARNAME=PACKAGES) || true
echo "file://$PACKAGES/ALL" >> $LOCALBASE/etc/pkgin/repositories.conf

# Initial vulnerability database update
$LOCALBASE/sbin/pkg_admin -K $LOCALBASE/pkgdb fetch-pkg-vulnerabilities
```

## Release archive for distribution

### Configure pkgin Repository Sources
Edit /usr/pkg-YYYYQN-nnnn/etc/pkgin/repositories.conf:


Create distribution tarball.

```bash
cd / && tar czf $PACKAGES/${LOCALBASE##*/}.tgz $LOCALBASE .
    # --exclude=work --exclude=distfiles .
```

Install tarball

### Log Locations
* Package installation logs: /usr/pkg-YYYYQN-nnnn/var/db/pkg/pkgin.log
* Repository update logs: /usr/pkg-YYYYQN-nnnn/var/db/pkgin/cache/
* System logs: /var/log/messages (for permission issues)

### Troubleshooting Common Issues

Test repository connectivity
```
curl -I http://your-repo-server/packages/YYYYQN-nnnn/Linux/x86_64/All/pkg_summary.bz2
```

Update package database
```
pkgin update
```

### Package Installation with Certification Tracking

```
# Build and install with certification logging
cd $pkgsrc/category/package
read -d '' pkgtag < <(sed -e 's/^./pkg/' -e 's/pkgsrc//' -e 's/HEAD/-HEAD/' < CVS/Tag) || true
read -d '' PKGNAME < <(bmake show-var VARNAME=PKGNAME) || true

# Vulnerability check before build
bmake audit-packages

# Build with tracking
bmake clean clean-depends package
pkg_update_summary -r $PACKAGES/All/pkg_summary.gz $PACKAGES/All

# Install with crypto signature verification (if available)
pkgin -y in $PKGNAME && {
    # Log certification record
    printf "%s pass PKGNAME=%s pkgtag=%s LOCALBASE=%s PWD=%s\n" \
        "$(date +%Y%m%d_%H%M%S)" "$PKGNAME" "$pkgtag" "$LOCALBASE" "$PWD" \
        >> $pkgsrc/pkg.log
} || {
    printf "%s fail PKGNAME=%s pkgtag=%s LOCALBASE=%s PWD=%s\n" \
        "$(date +%Y%m%d_%H%M%S)" "$PKGNAME" "$pkgtag" "$LOCALBASE" "$PWD" \
        >> $pkgsrc/pkg.log
    return 1
}
```

## Source Management

first get and extract the archive, and update it
  - https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.xz
  - https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.xz

### CVS Operations with Filtering

```
# Update existing checkout with work directory filtering
cd "$pkgsrc"
read -d '' Tag < <(sed 's/^T//' < CVS/Tag) || true
echo "Updating to $Tag..."
{ date ; pwd ; cvs -q upd -dP -r $Tag . 2>&1 ;} | sed '/\/work$/d' | tee -a ./cvs.log
```

## Package Integrity Verification

### Maintenance Automation
Implement daily maintenance covering source tree updates, package database consistency verification, and build artifact cleanup. Periodic routines include binary package repository updates and comprehensive system reporting.

* Daily maintenance routine
```
# update current
pkgsrc="$pre/pkgsrc-current" && cd "$pkgsrc" \
  && pkgtag="HEAD" && { date ; pwd ; echo $pkgtag ; cvs -q upd -dP -r $pkgtag . 2>&1 ;} \
     | sed -e '/\/work$/d' -e "s/^/$pkgtag /" | tee -a "${pkgsrc}/cvs.log"

# update release
pkgsrc="$pre/pkgsrc-stable" && cd "$pkgsrc" \
  && read Tag < <(sed 's/^T//' < CVS/Tag) \
  && { date ; pwd ; echo $pkgtag ; cvs -q upd -dP -r $pkgtag . 2>&1 ;} \
     | sed -e '/\/work$/d' -e "s/^/$pkgtag /" | tee -a "${pkgsrc}/cvs.log"

# Package database consistency and cleanup
$LOCALBASE/sbin/pkg_admin -K $LOCALBASE/pkgdb check
```

### Reproducible Build Verification
(incomplete section prototype placeholder)
```
# Verify bit-for-bit identical package builds
cd $pkgsrc/category/package
bmake clean
bmake package
cp $PACKAGES/All/$PKGNAME.t?z /tmp/build1.t?z

# Rebuild and compare
bmake clean
bmake package  
cmp $PACKAGES/All/$PKGNAME.t?z /tmp/build1.t?z && {
    echo "PASS: Reproducible build verified"
} || {
    echo "FAIL: Build not reproducible"
}
```

### Crypto Signature Verification
(incomplete section prototype placeholder)
```
# Package integrity verification with signatures (when available)
# Crypto signatures provide verification of package install integrity
# beyond reproducible builds
cd $PACKAGES/All
for pkg in *.t?z; do
    [ -f "$pkg.sig" ] && {
        # Verify package signature
        signify -V -m "$pkg" -p /etc/signify/pkgsrc.pub && {
            echo "PASS: $pkg signature verified"
        } || {
            echo "FAIL: $pkg signature invalid"
        }
    }
done
```

## Cross-Compilation Support
(incomplete section prototype placeholder)
### NetBSD Toolchain Setup
```
# Prepare NetBSD source toolchain for cross-builds
localpre=/usr/src
cd $localpre
ftp -a http://cdn.netbsd.org/pub/NetBSD/NetBSD-release-10/tar_files/src.tar.gz
tar xzf src.tar.gz
read -d '' srctag < <(sed 's/^T//' < src/CVS/Tag) || true
mv src $srctag

# Cross-compilation mk.conf additions
cat >> $LOCALBASE/etc/mk.conf << EOF
# Cross-compilation settings
USE_CROSS_COMPILE?=     yes
USETOOLS=               yes
TOOLDIR=                /usr/obj/tooldir.NetBSD-6.1-amd64
CROSS_DESTDIR=          /usr/obj/destdir.evbppc
MAKEOBJDIRPREFIX=       $localpre/$srctag/objdir
MKHOSTOBJ=              yes

# Target architecture override
.if !empty(USE_CROSS_COMPILE:M[yY][eE][sS])
MACHINE_ARCH=           powerpc
.endif
EOF
```

## Maintenance Operations

### Package Verification and Reporting
(incomplete section prototype placeholder)
```
# Comprehensive package consistency verification
pkgin list | awk '{print $1}' | while read pkg; do
    echo -n "." >&2
    read -d '' pkgpath < <(pkgin pbd $pkg | awk -F= '/^PKGPATH=/ {print $2}') || true
    [ "$pkgpath" ] && {
        cd $pkgsrc/$pkgpath
        read -d '' expected < <(bmake show-var VARNAME=PKGNAME) || true
        [ "$pkg" = "$expected" ] || echo "MISMATCH: $pkg != $expected ($pkgpath)"
    } || cat >/dev/null  # Abort read loop on error
done
```

### Lifecycle Management
(incomplete section prototype placeholder)
```
# Archive bootstrap when certification expires
# Manual verification required - check pkg.log for active certifications
grep "$(basename $LOCALBASE)" $pkgsrc/pkg.log | tail -10
```


#### Repository URLs for this release
(incomplete section prototype placeholder)
http://your-repo-server/packages/YYYYQN-nnnn/Linux/x86_64/All

#### Initialize pkgin Database
(incomplete section prototype placeholder)
Update package database
```
sudo /usr/pkg-YYYYQN-nnnn/bin/pkgin update
```

#### Verify repository connectivity
(incomplete section prototype placeholder)
```
/usr/pkg-YYYYQN-nnnn/bin/pkgin avail | head -20
```

#### Monitoring and Maintenance
(incomplete section prototype placeholder)
Check repository connectivity for all releases
```bash
for release in /usr/pkg-*; do
  echo "Checking $(basename $release)..."
        $release/bin/pkgin update 2>&1 | grep -E "(error|updated|failed)"
        done

        # Monitor package installations
        tail -f /usr/pkg-*/var/db/pkg/pkgin.log

        # Audit installed packages across releases
        for release in /usr/pkg-*; do
            echo "=== $(basename $release) ==="
                $release/sbin/pkg_info | wc -l
                done
```

# Best Practices
* Release Naming: Use consistent YYYYQN-nnnn format (e.g., 2024Q1-0001)
* User Training: Provide use-pkgsrc script and documentation
* Monitoring: Regularly check repository connectivity and disk usage
* Security: Audit installed packages and maintain group permissions
* Cleanup: Remove unused releases to save disk space
* Documentation: Keep track of which releases are in use by teams/projects

## Reference Links

- [PKGSRC Targets](https://wiki.netbsd.org/pkgsrc/targets/)
- [Security Practices](https://www.unitedbsd.com/d/438-pkgsrc-security-practices)  
- [Hardening Guide](https://www.netbsd.org/docs/pkgsrc/hardening.html)
- [Cross-Compilation](https://www.netbsd.org/gallery/presentations/riastradh/asiabsdcon2015/pkgsrc-cross.pdf)
- [Repository Setup](https://www.anserinae.net/setting-up-a-pkgsrc-repository.html)
- [Reproducible Builds](https://tests.reproducible-builds.org/netbsd/netbsd.html)

---

## Excluded Input Elements (Completeness Audit)

The following code fragments and notes from the input were not integrated into this documentation:

1. **Darwin bootstrap archive extraction logic**: Complex pkgtag calculation with quarterly date arithmetic
2. **Detailed mk.conf cross-compilation variables**: MACHINE/MACHINE_ARCH platform detection
3. **Package framework requirements documentation**: YAML/JSON profile data format preferences, RACI matrices
4. **Complex package request/certification workflow**: UID-based tracking, purpose tables, archive/expire dates
5. **Advanced CVS tag manipulation**: Multiple sed expressions for tag transformation
6. **NFS mount considerations**: Performance warnings for network builds
7. **Specific package option examples**: gobject-introspection header modifications
8. **Package export/import workflows**: pkgin export processing loops

These elements represent advanced operational details beyond the scope of this expert administrator guide but may be valuable for specialized deployment scenarios.

---

*This guide assumes expert-level system administration knowledge and dedicated build account usage. The framework supports scientific computing requirements with emphasis on security, reproducibility, and certification tracking.*
