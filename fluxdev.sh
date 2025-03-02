#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

HF_TOKEN="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"

APT_PACKAGES=()
PIP_PACKAGES=()
NODES=(
     "https://github.com/XLabs-AI/x-flux-comfyui.git"
     "https://github.com/rgthree/rgthree-comfy.git"
     "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
     "https://github.com/kaibioinfo/ComfyUI_AdvancedRefluxControl.git"
)
WORKFLOWS=(
    "https://gist.githubusercontent.com/robballantyne/f8cb692bdcd89c96c0bd1ec0c969d905/raw/2d969f732d7873f0e1ee23b2625b50f201c722a5/flux_dev_example.json"
)

CLIP_MODELS=(
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"
    "https://huggingface.co/zer0int/CLIP-GmP-ViT-L-14/resolve/main/ViT-L-14-TEXT-detail-improved-hiT-GmP-TE-only-HF.safetensors"
)

CLIPV_MODELS=(
    "https://huggingface.co/Comfy-Org/sigclip_vision_384/resolve/main/sigclip_vision_patch14_384.safetensors"
)

LORAS_MODELS=(
       "https://huggingface.co/prithivMLmods/Ton618-Epic-Realism-Flux-LoRA/resolve/main/Epic-Realism-Unpruned.safetensors"
       "https://huggingface.co/strangerzonehf/Flux-Super-Realism-LoRA/resolve/main/super-realism.safetensors"
       "https://huggingface.co/prithivMLmods/Flux-Dalle-Mix-LoRA/resolve/main/dalle-mix.safetensors"
       "https://huggingface.co/strangerzonehf/Flux-Midjourney-Mix-LoRA/resolve/main/midjourney-mix.safetensors"
       "https://huggingface.co/strangerzonehf/Flux-Super-Blend-LoRA/resolve/main/Super-Blend.safetensors"
       "https://huggingface.co/prithivMLmods/Flux-Fine-Detail-LoRA/resolve/main/Fine-Detail.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/mjv6_lora.safetensors"
       "https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors"
       "https://huggingface.co/strangerzonehf/Flux-Super-Realism-LoRA/resolve/main/super-realism.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/anime_lora.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/art_lora.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/disney_lora.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/furry_lora.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/realism_lora.safetensors"
       "https://huggingface.co/XLabs-AI/flux-lora-collection/resolve/main/scenery_lora.safetensors"
)

CTRL_MODELS=(
       "https://huggingface.co/XLabs-AI/flux-controlnet-canny-v3/resolve/main/flux-canny-controlnet-v3.safetensors"
       "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-depth-controlnet-v3.safetensors"
       "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-hed-controlnet-v3.safetensors"
)


UNET_MODELS=()
VAE_MODELS=()

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    workflows_dir="${COMFYUI_DIR}/user/default/workflows"
    mkdir -p "${workflows_dir}"
    provisioning_get_files "${workflows_dir}" "${WORKFLOWS[@]}"
    provisioning_download "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors" "${COMFYUI_DIR}/models/unet"
    provisioning_download "https://huggingface.co/black-forest-labs/FLUX.1-Fill-dev/resolve/main/flux1-fill-dev.safetensors" "${COMFYUI_DIR}/models/unet"
    provisioning_download "https://huggingface.co/black-forest-labs/FLUX.1-Redux-dev/resolve/main/flux1-redux-dev.safetensors" "${COMFYUI_DIR}/models/style_models"
    wget --header="Authorization: Bearer $HF_TOKEN" -q --show-progress -O "${COMFYUI_DIR}/models/loras/FLUX.1-Turbo-Alpha.safetensors" "https://huggingface.co/alimama-creative/FLUX.1-Turbo-Alpha/resolve/main/diffusion_pytorch_model.safetensors"
    provisioning_download "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors" "${COMFYUI_DIR}/models/vae"
    provisioning_get_files "${COMFYUI_DIR}/models/clip" "${CLIP_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip_vision" "${CLIPV_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/loras" "${LORAS_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/xlabs/controlnets" "${CTRL_MODELS[@]}"
    provisioning_print_end
}

function provisioning_get_apt_packages() {
    [[ -n $APT_PACKAGES ]] && sudo $APT_INSTALL ${APT_PACKAGES[@]}
}

function provisioning_get_pip_packages() {
    [[ -n $PIP_PACKAGES ]] && pip install --no-cache-dir ${PIP_PACKAGES[@]}
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            [[ ${AUTO_UPDATE,,} != "false" ]] && ( cd "$path" && git pull && [[ -e $requirements ]] && pip install --no-cache-dir -r "$requirements" )
        else
            git clone "$repo" "$path" --recursive && [[ -e $requirements ]] && pip install --no-cache-dir -r "$requirements"
        fi
    done
}

function provisioning_get_files() {
    [[ -z $2 ]] && return 1
    dir="$1"
    mkdir -p "$dir"
    shift
    for url in "$@"; do
        provisioning_download "$url" "$dir"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n# Provisioning container...                  #\n# This will take some time...                #\n# Your container will be ready on completion #\n##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete: Application will start now\n\n"
}

function provisioning_download() {
    local auth_header=""
    [[ $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]] && auth_header="Authorization: Bearer $HF_TOKEN"
    wget --header="$auth_header" -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
}

[[ ! -f /.noprovisioning ]] && provisioning_start
