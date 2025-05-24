# PKGSRC Multi-Platform Deployment Guide

## Overview

This guide provides a parameterized PKGSRC framework supporting scientific computing requirements across Darwin, NetBSD, and Linux platforms. The system maintains multiple concurrent package environments with unique LOCALBASE paths, security hardening, vulnerability tracking, and certification management.

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

# Detect platform and set base paths
export OS=$(uname)
case "$OS" in *BSD|Linux) pre=/usr ;; Darwin) pre=/opt ;; esac
# identify available paths then add them to user env profile: ls -d1 $pre/pkg-*/{sbin,bin}
test -d /opt/pkg-2024Q4-67799-Darwin_22.6.0_arm64-14.2/bin  && path_prepend "$_"
test -d /opt/pkg-2024Q4-67799-Darwin_22.6.0_arm64-14.2/sbin && path_prepend "$_"

# LOCALBASE assignment - conditional on scenario:

# package building: set or discover existing source tag, and prefix

# Select source branch
export pkgsrc="$pre/pkgsrc-stable"
export pkgtag="pkgsrc-2025Q1" # manual set
read pkgtag < <(sed 's/^T//' $pkgsrc/CVS/Tag) # tag discovery
# OR: export pkgsrc="$pre/pkgsrc-current" pkgtag="HEAD"

# set LOCALBASE and pkgrev
read REPLY < <(sed "s,/bin/bmake,," < <(which bmake))
[ -d "$REPLY" ] && { export LOCALBASE="$REPLY" PKG_DBDIR="$REPLY/pkgdb"
    read pkgrev < <(basename "$LOCALBASE") ;}

# Bootstrap prefix: generate new revision identifier with hex timestamp and bootstrap
read pkgtag < <(awk '{m=$2-3;y=$1; if(m<=0){m+=12;y--} print "pkgsrc-" y "Q" (int((m-1)/3)+1)}' < <(date "+%Y %m"))
read -d '' now < <(awk -v nd=5 -v ts=$(date +%s) 'BEGIN{s=32-(4*nd);printf"%0"nd"x\n",int(ts/2^s)}') || true
pkgrev=${pkgtag/pkgsrc/pkg}-${now}-$(uname -msr | tr ' ' '_')
export LOCALBASE="$pre/$pkgrev" PKG_DBDIR="$LOCALBASE/pkgdb"

### Build Configuration Variables
```bash
export DISTDIR="$pre/dist"            # Shared source cache
export WRKOBJDIR="/tmp/work-$pkgrev"  # Build workspace (/dev/shm on Linux)
export PACKAGES="$pkgsrc/packages-$pkgrev"  # Binary package output
export OBJMACHINE="defined"           # Enable object directory separation
export MAKE_JOBS="$(cores)"           # Platform-specific CPU detection
```

**Workflow**: Users typically set `pkgsrc` in their environment, add LOCALBASE to PATH from bootstrap, discover `pkgtag` from source checkout, and use `which bmake` to determine LOCALBASE for package builds. During upgrades, these may be set manually when updating source before bootstrapping new install prefix.

## Quick Start

### Environment Setup (All Platforms)

```bash
# Detect platform and set base paths
export OS=$(uname)
case "$OS" in 
    *BSD|Linux) pre=/usr ;; 
    Darwin) pre=/opt ;; 
esac


# Export standard paths - LOCALBASE underpins all other build parameters
export pre pkgrev
export DISTDIR="$pre/dist"
export LOCALBASE="$pre/$pkgrev" 
export PACKAGES="$pkgsrc/packages-$pkgrev"
export OBJMACHINE="defined"

# Platform-specific build workspace
case "$OS" in
    Linux) export WRKOBJDIR="/dev/shm/work-${pkgrev}" ;;  # Use tmpfs for performance
    *) export WRKOBJDIR="/tmp/work-${pkgrev}" ;;
esac
```

## Platform-Specific Bootstrap

### Dedicated Build Account Setup
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

# CPU core detection - use physical cores for stability
read -d '' cores < <(sysctl -n hw.physicalcpu) || true

# Prepare target directory with sudo for unprivileged bootstrap
[ -d "$LOCALBASE" ] && { 
    echo "ERROR: Target exists: '$LOCALBASE'" >&2
    exit 1
} || sudo mv $(mktemp -d) $LOCALBASE

# Update source if exists with CVS filtering
[ -f "$pkgsrc/CVS/Tag" ] && {
    echo "Updating PKGSRC source..."
    cd "$pkgsrc"
    read -d '' Tag < <(sed 's/^T//' < CVS/Tag) || true
    { date ; pwd ; cvs -q upd -dP -r $Tag . 2>&1 ;} | sed '/\/work$/d' | tee -a ./cvs.log
}

# Bootstrap with make-jobs matching physical cores
cd "$pkgsrc/bootstrap"
[ -d work ] && rm -rf work
./bootstrap \
    --prefix "$LOCALBASE" \
    --workdir "$WRKOBJDIR" \
    --unprivileged \
    --prefer-pkgsrc yes \
    --make-jobs $cores
```

### NetBSD

```bash
# CPU core detection
read -d '' cores < <(sysctl -n hw.ncpu) || true

# Prepare target directory
[ -d "$LOCALBASE" ] && { 
    echo "ERROR: Target exists: '$LOCALBASE'" >&2
    exit 1  
} || {
    mkdir $(basename $LOCALBASE)
    su -m root -c "mv $(basename $LOCALBASE) $pre"
}

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
read -d '' cores < <(nproc) || true

# Prepare target directory
[ -d "$LOCALBASE" ] && { 
    echo "ERROR: Target exists: '$LOCALBASE'" >&2
    exit 1
} || sudo mv $(mktemp -d) $LOCALBASE

# Ensure /dev/shm workspace exists
[ -d "$WRKOBJDIR" ] || sudo mkdir -p "$WRKOBJDIR"
sudo chown $(whoami):$(id -gn) "$WRKOBJDIR"

# Bootstrap with Linux-specific optimizations
cd "$pkgsrc/bootstrap"
[ -d work ] && rm -rf work  
./bootstrap \
    --prefix "$LOCALBASE" \
    --workdir "$WRKOBJDIR" \
    --unprivileged \
    --prefer-pkgsrc yes \
    --make-jobs $cores
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
```bash
# Update vulnerability database before any package operations
$LOCALBASE/sbin/pkg_admin -K $LOCALBASE/pkgdb fetch-pkg-vulnerabilities

# Verify packages during build
cd $pkgsrc/category/package
bmake audit-packages      # Check for known vulnerabilities
```

### Runtime Vulnerability Monitoring
```bash
# Daily vulnerability report generation
cat > /usr/local/bin/pkgsrc-vuln-report << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

read -d '' LOCALBASE < <(which bmake | sed 's,/bin/bmake,,') || true
read -d '' PKG_DBDIR < <($LOCALBASE/bin/bmake -f- show-var VARNAME=PKG_DBDIR <<< '.include "../../mk/bsd.prefs.mk"') || true

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

```bash
# Set up environment - LOCALBASE determined from bmake location
export PATH="$LOCALBASE/bin:$LOCALBASE/sbin:$PATH"
read -d '' LOCALBASE < <(which bmake | sed 's,/bin/bmake,,') || true
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

### Package Installation with Certification Tracking

```bash
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
    exit 1
}
```

## Source Management

### CVS Operations with Filtering

```bash
# Update existing checkout with work directory filtering
cd "$pkgsrc"
read -d '' Tag < <(sed 's/^T//' < CVS/Tag) || true
echo "Updating to $Tag..."
{ date ; pwd ; cvs -q upd -dP -r $Tag . 2>&1 ;} | sed '/\/work$/d' | tee -a ./cvs.log
```

## Package Integrity Verification

### Reproducible Build Verification
```bash
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
```bash
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

### NetBSD Toolchain Setup
```bash
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
```bash
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
```bash
# Archive bootstrap when certification expires
# Manual verification required - check pkg.log for active certifications
grep "$(basename $LOCALBASE)" $pkgsrc/pkg.log | tail -10

# Clean build artifacts
find $pkgsrc -name work -type d -exec rm -rf "$WRKOBJDIR"/{} \; 2>/dev/null || true
```

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
