#!/usr/bin/env bash

compress() {
    tar cvzf $1.tar.gz $1
}

ftmuxp() {
    if [[ -n $TMUX ]]; then
        return
    fi

    # get the IDs
    ID="$(ls $XDG_CONFIG_HOME/tmuxp | sed -e 's/\.yml$//')"
    if [[ -z "$ID" ]]; then
        tmux new-session
    fi

    create_new_session="Create New Session"

    ID="${create_new_session}\n$ID"
    ID="$(echo $ID | fzf | cut -d: -f1)"

    if [[ "$ID" = "${create_new_session}" ]]; then
        tmux new-session
    elif [[ -n "$ID" ]]; then
        # Rename the current urxvt tab to session name
        printf '\033]777;tabbedx;set_tab_name;%s\007' "$ID"
        tmuxp load "$ID"
    fi
}

scratchpad() {
    "$DOTFILES/zsh/scratchpad.sh"
}

f() {
    if [ $# -eq 0 ]
    then
        fzf
        return 0
    fi

    calling_script_dir="$PWD"

    # store the program
    program="$1"

    # pop first argument off the list
    shift

    # store any option flags
    command_options="$@"

    search_dir=/
    cd "$search_dir"

    # store the files from fzf
    fzf_files=$(fzf --multi)

    # TODO: Prepend search dir to each file
    fzf_files="$search_dir$fzf_files"

    cd "$calling_script_dir"

    # if no files returned from fzf, return to the terminal
    if [ -z "${fzf_files}" ]; then
        return 1
    fi

    # if the program is gui, run in background
    if [[ "$program" =~ ^(nautilus|zathura|evince|vlc|eog|kolourpaint)$ ]]; then
        fzf_files="$fzf_files &"
    fi

    if [ -z "$command_options" ]; then
        $program $fzf_files
    else
        $program $command_options $fzf_files
    fi
}

updatesys() {
    sh "$DOTFILES/update.sh"
}

ssh_auto() {
    ssh -t $1@$2 '
        echo "Starting automated environment installation!"
        INSTALLER_BASE_DIR="${HOME}/automatic_environment_installer"

        echo "Checking if environment is already present"
        if [ -d "${INSTALLER_BASE_DIR}" ] && [ ! -z $(ls -A "${INSTALLER_BASE_DIR}") ]; then
            echo "Everything appears to already been installed!"
            exit 0
        fi

        echo "Environment not already present, moving ahead with installation"
        echo "Creating ${INSTALLER_BASE_DIR}"
        mkdir -p "${INSTALLER_BASE_DIR}"

        # SSHED_ENV_INSTALLER
        SSHED_ENV_INSTALLER_DIR="${INSTALLER_BASE_DIR}/sshed_env_installer"

        git clone https://github.com/Brandon-Hubacher/sshed_env_installer.git "${SSHED_ENV_INSTALLER_DIR}"

        cd "${SSHED_ENV_INSTALLER_DIR}"

        ./install.sh

        # ORC3 INSTALLATION
        mkdir -p "${HOME}/orc3_repo_test"

        if [ -z $(ls -A "${HOME}/orc3_repo_test") ]; then
            cd "$HOME/orc3_repo_test"
            git clone git@github.amd.com:dcgpu-validation/orc3.git
            cd orc3

            sudo orc_install/install_pyenv.sh

            orc_python orc_install/install.py --venv=/home/"$USER"/orc3_repo_test/orc3_py_venv dev
        fi
    '

    ssh $1@$2 -t "zsh --login"
}
