WIP
----

Setup
--
- docker
- ssh
- gitconfig
- zram/swap

Variables
--
- GITHUB_TOKEN
- GH_RELEASES_REPO
- SF_USER
- SF_RELEASES_REPO
- TELEGRAM_TOKEN
- TELEGRAM_CHAT
- SF_USER

Authentication:
while github releases relies on the token, ota info pushing to a github repo and the sourceforge upload require ssh keys, that are added in your account and gitconfig.

Credits/Reference
--
- https://github.com/alsutton/aosp-build-docker-images/blob/main/debian-12-aosp.dockerfile
- https://github.com/Jarlpenguin/releases
- https://github.com/ederevx/android_scripts
- https://github.com/LeafOS-Project/leaf_build
- https://github.com/lineageos4microg/docker-lineage-cicd
- https://github.com/amyROM/vendor_amy/blob/207d5e32c3fba38b9fe1ab9cd12c71ca6b81d653/scripts/generate_json_build_info.sh

github release taken from
- https://github.com/Jarlpenguin/releases/raw/main/bin/github-release
