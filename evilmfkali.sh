# MIT License, see LICENSE file
# Author: Davide Girardi - GiRa

# Run this script to get Kali Linux ready for the Evil Mainframe training

##### Variables ####
export INSTALL_PACKAGES="openvpn x3270 xfonts-x3270-misc net-tools pwgen tnftp git metasploit-framework python"
export LABS_REPO="https://github.com/mainframed/Labs.git"
export LOG_FILE="/var/log/evilmf_deployment.log"

#####################################
#                                   #
#    Do not edit below this line    #
#                                   #
#####################################

# We want to exit if anything goes wrong
set -o errexit

function progress_info() {
    echo
    echo -en '\E[1;33m'
    echo "$*"
    tput sgr0
}

function run_and_log()
{
    if ! $* &>>$LOG_FILE
    then
        echo -e "$* \n COMMAND FAILED \n Check $LOG_FILE for issues"
        return 1
    fi
}

function install_packages() {
    DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get -y install $*
}

function clone_labs() {
    cd $HOME
    LABS_GIT=$(basename $LABS_REPO)
    LABNAME=${LABS_GIT/.git}
    if [ -d $HOME/$LABNAME ]
    then
        echo ""
        echo "There is already a $HOME/$LABNAME, the script will skip git cloning from $LABS_REPO"
        echo "Press enter to continue..."
        read
    fi
    git clone $LABS_REPO
}

function generate_x3270_config() {
    cat << EOF > $HOME/.x3270pro
x3270.emulatorFont: 3270gt24
x3270.marginedPaste: true
x3270.model: 2
x3270.verifyHostCert: false
EOF
}

function get_svn_nmap() {
    DEBIAN_FRONTEND=noninteractive
    if ! grep -E '^deb-src http://http.kali.org/kali kali-rolling main non-free contrib' /etc/apt/sources.list > /dev/null
    then
        echo 'deb-src http://http.kali.org/kali kali-rolling main non-free contrib' >> /etc/apt/sources.list
    fi
    apt-get update
    apt-get install -y subversion
    apt-get build-dep -y nmap
    mkdir -p /tmp/nmap_svn_evilmf
    cd /tmp/nmap_svn_evilmf
    svn checkout "https://svn.nmap.org/nmap/"
    cd nmap
    ./configure --with-liblua=included
    make
    make install
}

function get_labs() {
    git clone --depth=1 $LABS_REPO
}

function configure_msf() {
    systemctl enable --now postgresql
    msfdb init
}

function intro_text() {
    echo
    echo -en '\E[1;34m'
    cat << EOF
Evil Mainframe Kali Linux deployment

To see command progress, run:
tail -f $LOG_FILE
EOF
    tput sgr0
}

function main() {
    intro_text
    progress_info Install needed packages via apt
    run_and_log install_packages $INSTALL_PACKAGES
    progress_info Generate x3270 configuration
    run_and_log generate_x3270_config
    progress_info Install nmap from SVN
    run_and_log get_svn_nmap
    progress_info Configure Metasploit framework
    run_and_log configure_msf
    progress_info Get the labs
    run_and_log get_labs
}

main
