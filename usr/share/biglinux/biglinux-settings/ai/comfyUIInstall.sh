#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"

# Executes tasks.
updateTask() {
  if [[ "$function" == "install" ]]; then
    # clone and venv
    git clone https://github.com/Comfy-Org/ComfyUI.git $HOME/ComfyUI
    cd $HOME/ComfyUI
    python -m venv .

    # discover GPU
    vgaList=$(lspci | grep -iE "VGA|3D|Display")
    if [[ $(echo $vgaList | grep -Ei '(VGA|3D|Display).*(radeon|amd|\bati)') ]]; then
      gpu='amd'
    elif [[ $(echo $vgaList | grep -i nvidia) ]]; then
      gpu='nvidia'
    # elif [[ $(echo $vgaList | grep -i ????) ]]; then
    #     gpu='intel'
    # else
    #   gpu='cpu'
    fi

    # install GPU depends
    if [ -z "$gpu" ];then
      echo "GPU not found"
      exit 1
    #amd
    elif [ "$gpu" = "amd" ];then
      bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm7.1
    #intel NPX
    elif [ "$gpu" = "intel" ];then
      bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
    #nvidia
    elif [ "$gpu" = "nvidia" ];then
      bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130
    fi

    bin/pip install comfy-cli
    bash -c "yes | bin/comfy install --$gpu --restore"

    sleep 1
  else
    # stop service
    kill $(ps aux | grep -i "$HOME/ComfyUI/bin/python $HOME/ComfyUI/main.py" | grep -v grep | awk '{print $2}')
    # erase comfyUI folder
    rm -rf "$HOME/ComfyUI"

    sleep 1
  fi
  return 0
}
updateTask
exitCode=$?

# Exits the script with the correct exit code
exit $exitCode
