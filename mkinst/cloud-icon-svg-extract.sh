#!/usr/bin/env bash

# AWS Architecture Icons and Google Cloud Icons
#
# Get the "official AWS icon set for building architecture diagrams"
# and the Google Cloud Icon collection, with fixed filenames, removed
# png files, only the largest svn files per icon, a txt index and html
# swatch. Runtime is about 30 seconds, after the download completes.
# 
# (C) 2021-2022 George Georgalis <george@galis.org> unlimited use with this notice

set -e
mkdir -p tmp


#
### common functions for shell verbose management....
#

devnul () { return $? ;}                                                   #:> never direct args
stderr () { [ "$*" ] && echo "$*" 1>&2 || true ;}                          #:> args to stderr, or noop if null
chkstd () { [ "$*" ] && echo "$*"      || true ;}                          #:> args to stdout, or noop if null
chkwrn () { [ "$*" ] && { stderr    "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
chkerr () { [ "$*" ] && { stderr    ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null
logwrn () { [ "$*" ] && { logger -s "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr+log args return 0, noop if null
logerr () { [ "$*" ] && { logger -s ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr+log args return 1, noop if null
chkexit () { [ "$*" ] && { stderr    ">>> $* <<<" ; exit 1   ;} || true ;} #:> err stderr args exit 1, noop if null
logexit () { [ "$*" ] && { logger -s ">>> $* <<<" ; exit 1   ;} || true ;} #:> err stderr+log args exit 1, noop if null


#
### Download icon sets
#

# https://aws.amazon.com/architecture/
# https://aws.amazon.com/architecture/icons/
# https://d1.awsstatic.com/webteam/architecture-icons/q3-2021/Asset-Package_09172021.49796a977327744ded96470f1f94aafb1512f401.zip
au=https://d1.awsstatic.com/webteam/architecture-icons/q3-2021/Asset-Package_09172021.49796a977327744ded96470f1f94aafb1512f401.zip
az=Asset-Package_09172021.49796a977327744ded96470f1f94aafb1512f401.zip
[ -f "$az" ] || curl --silent -N "$au" -o "$az"
[ -f "$az" ] || chkexit "no $az"

# https://cloud.google.com/icons
# https://cloud.google.com/icons/files/google-cloud-icons.zip
gu=https://cloud.google.com/icons/files/google-cloud-icons.zip
gz=google-cloud-icons.zip
[ -f "$gz" ] || curl --silent -N "$gu" -o "$gz"
[ -f "$gz" ] || chkexit "no $gz"

# https://docs.microsoft.com/en-us/azure/architecture/icons/
# https://arch-center.azureedge.net/icons/Azure_Public_Service_Icons_V4.zip
mu=https://arch-center.azureedge.net/icons/Azure_Public_Service_Icons_V4.zip
mz=Azure_Public_Service_Icons_V4.zip
[ -f "$mz" ] || curl --silent -N "$mu" -o "$mz"
[ -f "$mz" ] || chkexit "no $mz"

#
### fixup and consolidate AWS icons
#
       rm -rf tmp/svg-aws-tmp-*
t=$(mktemp -d tmp/svg-aws-tmp-XXXX)

unzip -q -d "$t" "$az"
find "$t" -depth -name __MACOSX -exec rm -rf \{\} \;
find "$t" -name \*.png -type f -delete
find "$t" -depth -type d | while IFS= read a ; do
    b=$(sed -Ee '
        s/ /_/g
        s/_[_]*/_/g
        ' <<<"$a")
    expr "$a" : "$b" >/dev/null || mv "$a" "$b"
    done # remove spaces from dirs
find "$t" -type f | while IFS= read a ; do
    b=$(sed -Ee '
        s/ /_/g
        s/_[_]*/_/g
        s/Res_AWS-App-Mesh-/Res_AWS-App-Mesh_/
        s/Res_AWS-Cloud-Map-/Res_AWS-Cloud-Map_/
        s/Res_AWS-IoT-/Res_AWS-IoT_/
        s/Res_Amazon-Database_Amazon-RDS/Res_Amazon-RDS/
        s/Res_App-Mesh/Res_AWS-App-Mesh/
        s/Amazon-S3-on-Outposts_Storage/Amazon-S3-on-Outposts-Storage/
        ' <<<"$a")
    expr "$a" : "$b" >/dev/null || [ -e "$b" ] || mv "$a" "$b"
    done # remove spaces from files, remove multiple underscore, mesh mesh fix and ...

find "$t" -type d -name Category\* \
    | while IFS= read a ; do 
        find "$a" -type f \
            | while IFS= read a ; do 
                # path ${a%/*}  file ${a##*/}
                b=$(sed -Ee 's/Arch-Category_/Category_/' <<<"${a##*/}")
                expr "$a" : "$b" >/dev/null || mv "$a" "${a%/*}/$b"
                done # filenames, Arch-Category is a Category
        done # the category icon directory
# Asset-Package_09172021/Category-Icons_07302021/Arch-Category_48/Category_AWS-Cost-Management_48.svg

find "$t" -type d -regex '.*/Architecture-Service[^/]*/[^/]*' \
    | while IFS= read a ; do 
        export n=${a##*/}
        find "$a" -type f \
            | while IFS= read a ; do 
                # path ${a%/*}  file ${a##*/}
                b=$(sed -e "s/^Arch/$n/" <<<"${a##*/}")
                expr "$a" : "$b" >/dev/null || mv "$a" "${a%/*}/$b"
                done # type filenames
        done # Architecture-Service types
# Asset-Package_09172021/Architecture-Service-Icons_09172021/Arch_End-User-Computing/64/Arch_Amazon-WorkSpaces_64.svg

find "$t" -type d -regex '.*/Resource[^/]*/[^/]*' \
    | while IFS= read a ; do 
        export n=${a##*/}
        find "$a" -type f \
            | while IFS= read a ; do 
                # path ${a%/*}  file ${a##*/}
                b=$(sed -e "s/^Arch./${n}_/" <<<"${a##*/}")
                expr "$a" : "$b" >/dev/null || mv "$a" "${a%/*}/$b"
                done # type filenames, {type}- normalized to {type}_
        done # Resource types
# Asset-Package_09172021/Resource-Icons_07302021/Res_Storage/Res_48_Light/Res_AWS-Backup_Backup-Plan_48_Light.svg
# ./Res_AWS-App-Mesh-Mesh_Light.svg
# ./Res_AWS-App-Mesh-Virtual-Node_Light.svg
# ./Res_AWS-App-Mesh-Virtual-Router_Light.svg
# ./Res_AWS-App-Mesh-Virtual-Service_Light.svg
# ./Res_AWS-App-Mesh_Mesh_Dark.svg
# ./Res_AWS-App-Mesh_Virtual-Gateway_Dark.svg 

find "$t" -type f -regex '.*48.svg$' \
    | while IFS= read a ; do 
      b=$(sed -Ee 's/48.svg$/64.svg/g' <<<"$a")
      [ "$( find "$t" -name "${b##*/}" )" ] || mv "${a}" "${b}"
    done
find "$t" -type f -regex '.*32.svg$' \
    | while IFS= read a ; do 
      b=$(sed -Ee 's/32.svg$/64.svg/g' <<<"$a")
      [ "$( find "$t" -name "${b##*/}" )" ] || mv "${a}" "${b}"
    done
find "$t" -type f -regex '.*16.svg$' \
    | while IFS= read a ; do 
      b=$(sed -Ee 's/16.svg$/64.svg/g' <<<"$a")
      [ "$( find "$t" -name "${b##*/}" )" ] || mv "${a}" "${b}"
    done
find -E "$t" -type f -regex '.*_(16|32|48).svg$' -delete
find -E "$t" -type f -regex '.*_48_(Light|Dark).svg$' \
    | while IFS= read a ; do 
      b=$(sed -Ee '
        s/_48_Dark.svg$/_Dark_64.svg/
        s/_48_Light.svg$/_Light_64.svg/
        ' <<<"$a")
      [ "$( find "$t" -name "${b##*/}" )" ] || mv "${a}" "${b}"
    done

find "$t" -type f | while IFS= read a ; do
    b=$(sed -Ee '
        s/ /_/g
        s/_[_]*/_/g
        s/_64.svg$/.svg/
        ' <<<"$a")
    expr "$a" : "$b" >/dev/null || [ -e "$b" ] || mv "$a" "$b"
    done 

rm -rf svg-aws # XXX
[ -e "svg-aws" ] && chkexit "svg-aws exists, aborting $t" || true
mkdir svg-aws
find "$t" -type f -name \*.svg \
    | while IFS= read a ; do
        # path ${a%/*}  file ${a##*/}
        b="${a##*/}"
        [ -e "svg-aws/$b" ] && chkwrn "svg-aws/$b and $a" || mv "$a" "svg-aws"
        done

(cd ./svg-aws
find . -type f -name \*svg | sort >../svg-aws.txt
find . -type f -name \*svg | sort \
    | while IFS= read a ; do
        echo "<br><img src='$a'> $a" >>index.html
        done
) # create aws indices


#
### fixup and consolidate GCP icons
#
       rm -rf tmp/svg-gcp-tmp-*
t=$(mktemp -d tmp/svg-gcp-tmp-XXXX)

unzip -q -d "$t" "$gz"
find "$t" -name \*.png -type f -delete

rm -rf svg-gcp # XXX
[ -e "svg-gcp" ] && chkexit "svg-gcp exists, aborting $t" || true
mkdir svg-gcp
find "$t" -type f | while IFS= read a ; do
        # path ${a%/*}  file ${a##*/}
        b="${a##*/}"
    [ -e "svg-gcp/$b" ] && chkwrn "svg-gcp/$b and $a" || mv "$a" "svg-gcp"
    done

(cd ./svg-gcp
find . -type f -name \*svg | sort >../svg-gcp.txt
find . -type f -name \*svg | sort \
    | while IFS= read a ; do
        echo "<br><img src='$a' width=64> $a" >>index.html
        done
) # create gcp indices

#
### fixup and consolidate Azure icons
#
       rm -rf tmp/svg-azure-tmp-*
t=$(mktemp -d tmp/svg-azure-tmp-XXXX)

unzip -q -d "$t" "$mz"
find "$t" -name \*.png -type f -delete

find "$t" -depth -type d | while IFS= read a ; do
    b=$(sed -Ee '
        s/ /_/g
        s/_[_]*/_/g
        ' <<<"$a")
    expr "$a" : "$b" >/dev/null || mv "$a" "$b"
    done # remove spaces from dirs
# Azure_Public_Service_Icons/Icons/Mixed Reality

find "$t" -type f | while IFS= read a ; do
    b=$(sed -Ee '
        s/ /_/g
        s/_[_]*/_/g
        ' <<<"$a" | tr -d '()' )
    expr "$a" : "$b" >/dev/null || [ -e "$b" ] || mv "$a" "$b"
    done # remove spaces from files, remove multiple underscore

find "$t" -type d -regex '.*/Icons[^/]*/[^/]*' \
    | while IFS= read a ; do 
        export n=${a##*/}
        n=$(sed '
                s/AI_+_Machine_Learning/AIML/
                s/Management_+_Governance/Management-Governance/
                s/^Azure_//
                s/ /_/g
                s/_[_]*/_/g
                s/^/Azure_/
                ' <<<"$n")
        find "$a" -type f \
            | while IFS= read a ; do 
                # path ${a%/*}  file ${a##*/}
                b=$(sed -e "s/^[[:digit:]]*-icon-service-/${n}_/" <<<"${a##*/}")
                expr "$a" : "$b" >/dev/null || mv "$a" "${a%/*}/$b"
                done # type filenames
        done # Azure_Public_Service_Icons
# Azure_Public_Service_Icons/Icons/Internet of Things/10192-icon-service-Time-Series-Insights-Access-Policies.svg

rm -rf svg-azure # XXX
[ -e "svg-azure" ] && chkexit "svg-azure exists, aborting $t" || true
mkdir svg-azure
find "$t" -type f -name \*.svg \
    | while IFS= read a ; do
        # path ${a%/*}  file ${a##*/}
        b="${a##*/}"
        [ -e "svg-azure/$b" ] && chkwrn "svg-azure/$b and $a" || mv "$a" "svg-azure"
        done 

(cd ./svg-azure
find . -type f -name \*svg | sort >../svg-azure.txt
find . -type f -name \*svg | sort \
    | while IFS= read a ; do
        echo "<br><img src='$a' width=64> $a" >>index.html
        done
) # create Azure indices

chkwrn $(find svg-aws   -type f -name \*svg | wc -l) 'icons: ./svg-aws   ./svg-aws.txt   ./svg-aws/index.html'
chkwrn $(find svg-gcp   -type f -name \*svg | wc -l) 'icons: ./svg-gcp   ./svg-gcp.txt   ./svg-gcp/index.html'
chkwrn $(find svg-azure -type f -name \*svg | wc -l) 'icons: ./svg-azure ./svg-azure.txt ./svg-azure/index.html'
exit 0
